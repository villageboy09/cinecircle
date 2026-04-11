import 'package:flutter/material.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo Image
              Image.asset(
                'assets/cinelogo.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              // Subtitle
              const Text(
                'Where film talent connects.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
