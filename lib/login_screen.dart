import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number and password')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/cinecircle_api.php'),
        body: {
          'action': 'login',
          'mobile_number': phone,
          'password': password,
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
         final user = data['user'];
         final prefs = await SharedPreferences.getInstance();
         
         await prefs.setString('user_name', user['full_name'] ?? 'User');
         await prefs.setString('user_phone', user['mobile_number'] ?? phone);
         await prefs.setString('account_type', user['account_type'] ?? 'Public');

         if (!mounted) return;
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (context) => const HomeScreen()),
         );
      } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(data['message'] ?? 'Login failed')),
         );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/cinelogo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'Sign in to continue your film\nnetwork journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 40),
              // Phone Input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontFamily: 'Google Sans',
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontFamily: 'Google Sans',
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Log In Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text(
                      'Log In',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    children: [
                      TextSpan(text: 'New to CineCircle? '),
                      TextSpan(
                        text: 'Create account',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
