import 'package:flutter/material.dart';
import 'package:municipal_e_challan/pages/dashboard_page.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart'; // Import login page

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController loginIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String role = 'inspector';

  final ApiService apiService = ApiService();
  bool isLoading = false;

  void submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final resp = await apiService.registerOfficer(
          username: usernameController.text.trim(),
          mobile: mobileController.text.trim(),
          email: emailController.text.trim(),
          loginId: loginIdController.text.trim(),
          password: passwordController.text,
          role: role,
        );

        // Registration succeeded — attempt automatic login
        try {
          final loginResp = await apiService.loginWithCredentials(
            loginIdController.text.trim(),
            passwordController.text,
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', loginResp.accessToken);
          await prefs.setString('token_type', loginResp.tokenType);
          await prefs.setInt('user_id', loginResp.userId);
          await prefs.setString('username', loginResp.username);
          await prefs.setString('role', loginResp.role);
          try {
            await prefs.setInt('expires_in', loginResp.expiresIn);
            await prefs.setInt(
              'token_timestamp',
              DateTime.now().millisecondsSinceEpoch,
            );
          } catch (_) {}

          // Navigate to dashboard and clear back stack
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage()),
            (route) => false,
          );
        } catch (loginError) {
          // If auto-login fails, show a message and navigate to Login page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registered but auto-login failed: ${loginError.toString()}',
              ),
            ),
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: ${e.toString()}')),
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
              // ✅ Clean City Image in Center
              Image.asset('assets/images/clean_city.png', height: 200),
              SizedBox(height: 24),

              Text(
                "Register Officer",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username Field
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Mobile Number Field
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Mobile Number",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length != 10) {
                          return 'Enter valid 10 digit mobile number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        final emailRegex = RegExp(
                          r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Login ID Field
                    TextFormField(
                      controller: loginIdController,
                      decoration: InputDecoration(
                        labelText: "Login ID",
                        prefixIcon: Icon(Icons.account_circle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a login id';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitRegistration,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // ✅ Already have account? Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already registered? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                          },
                          child: Text(
                            "Login here",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
