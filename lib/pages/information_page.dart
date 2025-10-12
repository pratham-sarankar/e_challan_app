import 'package:flutter/material.dart';

class InformationPage extends StatelessWidget {
  final List<Map<String, String>> rulesInfo = [
    {
      "rule": "C&D वेस्ट का सड़क पर निप्तारण",
      "amount": "₹ 2000",
      "reference": "Solid Waste Management Rules, 2016",
    },
    {
      "rule": "हरा/नीला/लाल डस्टबिन न रखना",
      "amount": "₹ 500",
      "reference": "नगर निगम अधिनियम धारा",
    },
    {
      "rule": "फुटपाथ पर गुमटी/ठेला लगाना",
      "amount": "₹ 1000",
      "reference": "अतिक्रमण अधिनियम",
    },
    {
      "rule": "प्रतिबंधित प्लास्टिक का उपयोग",
      "amount": "₹ 1500",
      "reference": "Plastic Waste Mgmt Rules, 2016",
    },
    {
      "rule": "बिना अनुमति व्यापार",
      "amount": "₹ 2500",
      "reference": "छ.ग. नगर पालिका निगम अधिनियम, धारा",
    },
  ];

  InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rule Violation Info")),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: rulesInfo.length,
        itemBuilder: (context, index) {
          final rule = rulesInfo[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                rule["rule"]!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Reference: ${rule["reference"]}"),
              trailing: Text(
                rule["amount"]!,
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          );
        },
      ),
    );
  }
}
