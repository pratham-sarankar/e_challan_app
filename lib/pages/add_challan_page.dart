import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:municipal_e_challan/models/challan_response.dart';
import 'package:municipal_e_challan/models/challan_type.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dashboard_page.dart';
import 'payment_page.dart';

class AddChallanPage extends StatefulWidget {
  const AddChallanPage({super.key});

  @override
  _AddChallanPageState createState() => _AddChallanPageState();
}

class _AddChallanPageState extends State<AddChallanPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final wardController = TextEditingController();
  List<File> images = [];
  final ApiService _api_service = ApiService();
  bool _isSubmitting = false;
  List<ChallanType> _challanTypes = [];
  bool _isLoadingTypes = false;
  double? _latitude;
  double? _longitude;

  // (rulesInfo removed — dropdown driven only by server)

  // Unselected by default; holds the chosen ChallanType from API
  ChallanType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadChallanTypes();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable from settings.',
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadChallanTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final types = await _api_service.getChallanTypes();
      // Debug: log loaded types
      for (final t in types)
        print('[AddChallanPage] type=${t.typeName} fine=${t.fineAmount}');
      setState(() {
        _challanTypes = types;
      });

      // If a type was previously selected, try to rebind it to the newly-loaded list
      if (_selectedType != null) {
        final selName = _selectedType!.typeName.trim().toLowerCase();
        try {
          final restored = _challanTypes.firstWhere(
            (t) => t.typeName.trim().toLowerCase() == selName,
          );
          setState(() {
            _selectedType = restored;
            amountController.text = restored.fineAmount.toString();
          });
        } catch (_) {
          // previously selected type not present in new list; clear selection
          setState(() {
            _selectedType = null;
            amountController.clear();
          });
        }
      }
    } catch (e) {
      // show a small UI message so developers/testers know fetching failed
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load challan types: ${e.toString()}'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoadingTypes = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    amountController.dispose();
    notesController.dispose();
    wardController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    var status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera permission denied"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      // Add the picked file directly without launching an additional crop screen
      setState(() {
        images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> submitChallan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure we have a location before submitting
    if (_latitude == null || _longitude == null) {
      await _determinePosition();
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to get location. Please ensure location is enabled and try again.',
            ),
          ),
        );
        return;
      }
    }

    final fullName = nameController.text.trim();
    final contactNumber = mobileController.text.trim();
    final challanName = _selectedType?.typeName ?? 'Violation';

    // Require server-provided challan types — do not fall back to static rules
    if (_challanTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Challan types not loaded from server. Please try again.',
          ),
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    // Ensure a challan type from server is selected
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rule violation from the list')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final ChallanType matched = _selectedType!;
    final int challanTypeId = matched.id;
    // Prefer the user-edited amount if present and numeric; fall back to server fine.
    int fineAmount;
    final amtText = amountController.text.trim();
    if (amtText.isNotEmpty) {
      final parsed = int.tryParse(amtText);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid numeric fine amount')),
        );
        setState(() => _isSubmitting = false);
        return;
      }
      fineAmount = parsed;
    } else {
      fineAmount = matched.fineAmount;
    }
    final description = notesController.text.trim();
    final wardNumber = wardController.text.trim().isNotEmpty
        ? wardController.text.trim()
        : '0';
    final latitude = _latitude ?? 0.0;
    final longitude = _longitude ?? 0.0;

    setState(() => _isSubmitting = true);
    try {
      final ChallanResponse resp = await _api_service.createChallan(
        fullName: fullName,
        contactNumber: contactNumber,
        challanTypeId: challanTypeId,
        challanName: challanName,
        fineAmount: fineAmount,
        description: description,
        wardNumber: wardNumber,
        latitude: latitude,
        longitude: longitude,
      );

      // Add to local dashboard list using server response
      final newChallan = {
        'id': resp.id,
        'challan_id': resp.challanId,
        'name': fullName,
        'mobile': contactNumber,
        'latitude': latitude,
        'longitude': longitude,
        'rule': challanName,
        'amount': resp.fineAmount.toString(),
        'notes': description,
        'image_urls': resp.imageUrls,
        'image_count': resp.imageCount,
        'status': 'Unpaid',
        'created_at': resp.createdAt,
      };

      DashboardPage.challans.add(newChallan);

      // If user added images locally, upload them to the server for this challan
      if (images.isNotEmpty) {
        try {
          final uploadData = await _api_service.uploadChallanImages(
            resp.challanId,
            images,
          );
          // uploadData contains uploaded_files and total_uploaded per API sample
          newChallan['uploaded_files'] = uploadData['uploaded_files'] ?? [];
          newChallan['total_uploaded'] =
              uploadData['total_uploaded'] ??
              (uploadData['uploaded_files'] as List?)?.length ??
              0;
        } catch (uploadErr) {
          // If image upload fails, show a message but keep the challan created
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Challan created but image upload failed: ${uploadErr.toString()}',
              ),
            ),
          );
        }
      }

      // Show success dialog (same as before)
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Challan Issued Successfully",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "Your challan has been recorded successfully. You can make the payment now or later from your dashboard.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          "PAY LATER",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentPage(
                                index: DashboardPage.challans.length - 1,
                                challan: DashboardPage.challans.isNotEmpty
                                    ? DashboardPage.challans.last
                                    : null,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "PAY NOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create challan: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: amountController is auto-filled when a type is selected (in
    // onChanged / when types load). We avoid forcing controller updates in
    // build() so the user can edit the value after selection.
    // Dropdown uses server-provided `_challanTypes` directly; no local fallback.

    return Scaffold(
      appBar: AppBar(title: Text("Issue New Challan"), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(13),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Violator Name",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter violator name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: mobileController,
                  decoration: InputDecoration(
                    labelText: "Mobile Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (value.length != 10) {
                      return 'Please enter valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Use only API-provided challan types for the dropdown. Show loading/empty UI as needed.
                if (_isLoadingTypes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading rule violations...'),
                      ],
                    ),
                  )
                else if (_challanTypes.isEmpty)
                  // No types from server — inform user and disable submission
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select Rule Violation',
                        prefixIcon: Icon(Icons.gavel_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('No rule violations available'),
                    ),
                  )
                else
                  DropdownButtonFormField<ChallanType>(
                    isExpanded: true,
                    // Use initialValue instead of the deprecated `value`.
                    // Add a key so the FormField is recreated when the selected
                    // type changes — this ensures the initialValue reflects
                    // programmatic updates to `_selectedType`.
                    key: ValueKey(_selectedType?.id ?? 'none'),
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: "Select Rule Violation",
                      prefixIcon: Icon(Icons.gavel_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Choose a rule',
                    ),
                    items: _challanTypes
                        .map(
                          (t) => DropdownMenuItem<ChallanType>(
                            value: t,
                            // Only show the type name (no fine amount in dropdown)
                            child: Text(
                              t.typeName,
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (ChallanType? value) {
                      setState(() {
                        _selectedType = value;
                        if (value != null) {
                          amountController.text = value.fineAmount.toString();
                          // Debug log selection
                          print(
                            '[AddChallanPage] selected type=${value.typeName} fine=${value.fineAmount}',
                          );
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Selected: ${value.typeName} — ₹${value.fineAmount}',
                                ),
                                duration: Duration(milliseconds: 900),
                              ),
                            );
                        } else {
                          amountController.clear();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a rule violation';
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  // When a server-provided challan type is selected, lock the amount to that
                  // type's fine and prevent manual edits. If selection is cleared the field
                  // becomes editable again.
                  decoration: InputDecoration(
                    labelText: "Fine Amount",
                    // Use prefixText so value and symbol align nicely.
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(fontWeight: FontWeight.w600),
                    // Field is editable even when a type is selected; server fine will be
                    // auto-filled but user can edit it.
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fine amount';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: "Additional Notes",
                    prefixIcon: Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: wardController,
                  decoration: InputDecoration(
                    labelText: "Ward Number (Optional)",
                    prefixIcon: Icon(Icons.local_police_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Evidence Photos",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length + 1,
                        itemBuilder: (context, index) {
                          if (index == images.length) {
                            return GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => Container(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.camera_alt),
                                          title: Text("Take Photo"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            pickImage(ImageSource.camera);
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.photo_library),
                                          title: Text("Choose from Gallery"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            pickImage(ImageSource.gallery);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(77),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(images[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      images.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : submitChallan,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? "Submitting..." : "ISSUE CHALLAN",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
