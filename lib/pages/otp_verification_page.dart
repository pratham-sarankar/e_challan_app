import 'package:flutter/material.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'dashboard_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String mobileNumber;

  const OtpVerificationPage({super.key, required this.mobileNumber});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final otpController = TextEditingController();
  final ApiService apiService = ApiService();
  bool isLoading = false;

  void verifyOtp() async {
    if (otpController.text.isNotEmpty) {
      setState(() => isLoading = true);
      try {
        final token = await apiService.verifyOtp(widget.mobileNumber, otpController.text);
        // You can save the token for future authenticated requests
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify OTP: ${e.toString()}')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/images/clean_city.png', height: 200),
              SizedBox(height: 24),
              Text(
                "OTP Verification",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 16),
              Text("Enter the OTP sent to ${widget.mobileNumber}"),
              SizedBox(height: 32),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter OTP",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyOtp,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Verify OTP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
