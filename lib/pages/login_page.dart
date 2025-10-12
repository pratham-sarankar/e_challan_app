import 'package:flutter/material.dart';
import 'package:municipal_e_challan/pages/dashboard_page.dart';
import 'package:municipal_e_challan/pages/register_page.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginIdController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  final ApiService apiService = ApiService();

  Future<void> _login() async {
    final loginId = loginIdController.text.trim();
    final password = passwordController.text;
    if (loginId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both login ID and password')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final resp = await apiService.loginWithCredentials(loginId, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', resp.accessToken);
      await prefs.setString('token_type', resp.tokenType);
      await prefs.setInt('user_id', resp.userId);
      await prefs.setString('username', resp.username);
      await prefs.setString('role', resp.role);
      // Save expiry and timestamp to validate session on app restart
      try {
        await prefs.setInt('expires_in', resp.expiresIn);
        await prefs.setInt(
          'token_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (_) {}

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                SizedBox(
                  height: 200,
                  child: Image.asset('assets/images/clean_city.png'),
                ),
                SizedBox(height: 40),
                Text(
                  "Officer Login",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: loginIdController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Login ID",
                            prefixIcon: Icon(Icons.person),
                            hintText: "Enter your login id (email or username)",
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                            hintText: "Enter your password",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(153),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        Container(
                          width: 24,
                          height: 24,
                          margin: EdgeInsets.only(right: 10),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      Text("Login", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterPage()),
                        );
                      },
                      child: Text(
                        "Register here",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
