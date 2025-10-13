import 'package:flutter/material.dart';
import 'dart:async';

import 'package:vizpay_flutter/vizpay_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String amount = "";
  String tipAmount = "";
  String billNumber = "";
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> makeSale() async {
    try {
      final response = await VizpayFlutter.startSaleTransaction(
        amount: "1.00",
        billNumber: "BILL123",
        sourceId: "SOURCE9876",
        tipAmount: "00",
        printFlag: true,
      );
      print("Response: $response");
      if (response != null) {
        if (response["STATUS_CODE"] == "00") {
          print("✅ Transaction Success: ${response["STATUS_MSG"]}");
        } else {
          print("❌ Transaction Failed: ${response["STATUS_MSG"]}");
        }
      } else {
        print("⚠️ No response from payment app");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade900,
          title: const Text(
            'Billing App',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(hint: Text("Amount")),
                        keyboardType: TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          } else if (double.tryParse(value) == null) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          amount = double.parse(value!).toStringAsFixed(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(hint: Text("Tip Amount")),
                        keyboardType: TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          } else if (double.tryParse(value) == null) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          tipAmount = double.parse(value!).toStringAsFixed(2);
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: InputDecoration(hint: Text("Bill Number")),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bill number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    billNumber = value!;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(
                      Size(double.infinity, 40),
                    ),
                  ),
                  onPressed: () {
                    makeSale();
                  },
                  child: Text("Sale"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
