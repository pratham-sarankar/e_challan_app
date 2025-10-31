import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:municipal_e_challan/models/challan_response.dart';
import 'package:municipal_e_challan/models/challan_type.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:municipal_e_challan/services/service_locator.dart';
import 'package:municipal_e_challan/cubits/challan_types_cubit.dart';
import 'package:municipal_e_challan/cubits/challan_types_state.dart';
import 'package:permission_handler/permission_handler.dart';

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

  late ChallanTypesCubit _cubit;

  // Unselected by default; holds the chosen ChallanType from API
  ChallanType? _selectedType;

  @override
  void initState() {
    super.initState();
    // Get the global cubit from service locator
    _cubit = getIt<ChallanTypesCubit>();
    
    // Load challan types if not already loaded
    if (_cubit.state is ChallanTypesInitial) {
      _cubit.loadChallanTypes();
    }
  }

  /// Helper method to get challan types from cubit state
  List<ChallanType> _getChallanTypes() {
    final state = _cubit.state;
    if (state is ChallanTypesLoaded) {
      return state.challanTypes;
    }
    return [];
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

    final fullName = nameController.text.trim();
    final contactNumber = mobileController.text.trim();
    final challanName = _selectedType?.typeName ?? 'Violation';

    // Get challan types using helper method
    final challanTypes = _getChallanTypes();

    // Require server-provided challan types — do not fall back to static rules
    if (challanTypes.isEmpty) {
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
    final latitude = 0.0; // Default latitude since geolocation is disabled
    final longitude = 0.0; // Default longitude since geolocation is disabled

    setState(() => _isSubmitting = true);

    // Show loading dialog
    _showLoadingDialog();

    try {
      final ChallanResponse newChallan = await _api_service.createChallan(
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

      // If user added images locally, upload them to the server for this challan
      if (images.isNotEmpty) {
        try {
          final uploadedImageUrls = await _api_service.uploadChallanImages(
            newChallan.challanId,
            images,
          );

          // uploadData contains uploaded_files and total_uploaded per API sample
          newChallan.imageUrls = uploadedImageUrls;
          newChallan.imageCount = uploadedImageUrls.length;
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

      // Dismiss loading dialog
      Navigator.of(context).pop();

      // Show success dialog (same as before)
      showDialog(
        context: context,
        barrierDismissible: false,
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
                              builder: (_) => PaymentPage(challan: newChallan),
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
      // Dismiss loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create challan: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Make dialog undismissible
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent back button dismissal
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 16,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withAlpha(245),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated loading indicator
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.upload_file,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Creating Challan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Please wait while we create your challan and upload evidence images...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress steps indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressStep(
                          context,
                          icon: Icons.description,
                          label: 'Creating',
                          isActive: true,
                        ),
                        Container(
                          width: 24,
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(77),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        _buildProgressStep(
                          context,
                          icon: Icons.cloud_upload,
                          label: 'Uploading',
                          isActive: images.isNotEmpty,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressStep(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withAlpha(77),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(153),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
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
                // Use BlocBuilder to reactively display challan types from global cubit
                BlocBuilder<ChallanTypesCubit, ChallanTypesState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    if (state is ChallanTypesLoading) {
                      return Padding(
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
                      );
                    } else if (state is ChallanTypesError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Select Rule Violation',
                                prefixIcon: Icon(Icons.gavel_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Error loading rule violations'),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _cubit.retry(),
                              icon: Icon(Icons.refresh),
                              label: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is ChallanTypesLoaded) {
                      final challanTypes = state.challanTypes;
                      if (challanTypes.isEmpty) {
                        return Padding(
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
                        );
                      }

                      return DropdownButtonFormField<ChallanType>(
                        isExpanded: true,
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
                        items: challanTypes
                            .map(
                              (t) => DropdownMenuItem<ChallanType>(
                                value: t,
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
                              print(
                                '[AddChallanPage] selected type=${value.typeName} fine=${value.fineAmount}',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                  'Selected: ${value.typeName} — ₹${value.fineAmount}',
                                ),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          }
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
                  );
                    } else {
                      // Initial state - should not happen since we load in initState
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Initializing...'),
                          ],
                        ),
                      );
                    }
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: images.length + 1,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 columns for better layout
                        childAspectRatio: 1,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
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
                              right: 4,
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
