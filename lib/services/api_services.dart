import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = Constants.apiBaseUrl;

  Future<void> registerOfficer(String fullName, String mobileNumber) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fullName': fullName, 'mobileNumber': mobileNumber}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register officer');
    }
  }

  Future<void> loginOfficer(String mobileNumber) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobileNumber': mobileNumber}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  Future<String> verifyOtp(String mobileNumber, String otp) async {
    final url = Uri.parse('$baseUrl/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobileNumber': mobileNumber, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token']; // Assuming a token is returned on success
    } else {
      throw Exception('Failed to verify OTP');
    }
  }
}
