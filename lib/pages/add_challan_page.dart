import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'dashboard_page.dart';
import 'payment_page.dart';
import 'package:permission_handler/permission_handler.dart';

class AddChallanPage extends StatefulWidget {
  const AddChallanPage({super.key});

  @override
  _AddChallanPageState createState() => _AddChallanPageState();
}

class _AddChallanPageState extends State<AddChallanPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  List<File> images = [];

  final List<Map<String, String>> rulesInfo = [
    {"rule": "C&D वेस्ट का सड़क पर निष्कासन(2000)", "amount": "2000"},
    {"rule": "हरा/नीला/लाल डस्टबिन न रखना(500)", "amount": "500"},
    {"rule": "फुटपाथ पर गुमठी/ठेला लगाना (1000)", "amount": "1000"},
    {"rule": "प्रतिबंधित प्लास्टिक का प्रयोग(1500)", "amount": "1500"},
    {"rule": "बिना अनुमति व्यापार(2500)", "amount": "2500"},
  ];

  String? selectedRule;

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    amountController.dispose();
    notesController.dispose();
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
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop Image', lockAspectRatio: false),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: false),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          images.add(File(croppedFile.path));
        });
      }
    }
  }

  void submitChallan() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    DashboardPage.challans.add({
      "name": nameController.text,
      "mobile": mobileController.text,
      "address": addressController.text,
      "rule": selectedRule,
      "amount": amountController.text,
      "notes": notesController.text,
      "images": images,
      "status": "Unpaid",
    });

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FadeInUp(
          duration: Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - Make it flexible
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
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
                      // Wrap the text in Expanded
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
      ),
    );
  }

  void _updateFineAmount(String? selectedRuleValue) {
    if (selectedRuleValue == null) {
      amountController.clear();
      return;
    }

    final selectedRuleData = rulesInfo.firstWhere(
      (ruleMap) => ruleMap["rule"] == selectedRuleValue,
      orElse: () => {},
    );

    if (selectedRuleData.isNotEmpty) {
      amountController.text = selectedRuleData["amount"] ?? "";
    } else {
      amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> rulesListText = rulesInfo
        .map((info) => info["rule"]!)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Issue New Challan"), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
                FadeInDown(
                  duration: Duration(milliseconds: 400),
                  child: TextFormField(
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
                ),
                SizedBox(height: 16),
                FadeInDown(
                  delay: Duration(milliseconds: 100),
                  duration: Duration(milliseconds: 400),
                  child: TextFormField(
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
                ),
                SizedBox(height: 16),
                FadeInDown(
                  delay: Duration(milliseconds: 200),
                  duration: Duration(milliseconds: 400),
                  child: TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: "Address",
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                    /*      validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },*/
                  ),
                ),
                SizedBox(height: 16),
                FadeInDown(
                  delay: Duration(milliseconds: 300),
                  duration: Duration(milliseconds: 400),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedRule,
                    decoration: InputDecoration(
                      labelText: "Select Rule Violation",
                      prefixIcon: Icon(Icons.gavel_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: rulesListText
                        .map(
                          (rule) => DropdownMenuItem(
                            value: rule,
                            child: Text(
                              rule,
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRule = value;
                        _updateFineAmount(value);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a rule violation';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                FadeInDown(
                  delay: Duration(milliseconds: 400),
                  duration: Duration(milliseconds: 400),
                  child: TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: "Fine Amount",
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    // enabled: false,
                  ),
                ),
                SizedBox(height: 16),
                FadeInDown(
                  delay: Duration(milliseconds: 500),
                  duration: Duration(milliseconds: 400),
                  child: TextFormField(
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
                ),
                /*        SizedBox(height: 24),
                FadeInDown(
                  delay: Duration(milliseconds: 600),
                  duration: Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Evidence Photos",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                ),*/
                SizedBox(height: 24),
                FadeInUp(
                  duration: Duration(milliseconds: 400),
                  child: ElevatedButton(
                    onPressed: submitChallan,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "ISSUE CHALLAN",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
