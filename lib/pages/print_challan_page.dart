import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:printing/printing.dart'; // Add this package for printing
import 'package:pdf/widgets.dart' as pw; // For PDF generation

void _printChallan(BuildContext context, Map<String, dynamic> challan) async {
  // Show loading animation
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
      ),
    ),
  );

  // Generate PDF (simplified example)
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        children: [
          pw.Text('Challan Receipt', style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 20),
          pw.Text('Name: ${challan['name']}'),
          pw.Text('Amount: ₹${challan['amount']}'),
          // Add more details as needed
        ],
      ),
    ),
  );

  // Delay to simulate processing
  await Future.delayed(Duration(seconds: 1));

  // Close loading dialog
  Navigator.pop(context);

  // Show print preview
  await Printing.layoutPdf(onLayout: (format) => pdf.save());

  // Show success animation
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/success.json', // Add your animation file
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20),
          Text(
            'Challan Printed Successfully!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
      ],
    ),
  );
}
