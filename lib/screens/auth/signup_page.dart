// [IMPORT] Libraries
import 'package:soro/main.dart';
import 'package:flutter/material.dart';

// [IMPORT] Screens
import 'package:soro/screens/home_page.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary_100,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // [TITLE] Sign Up
            const Text(
              "Sign Up",
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.text_800,
              ),
            ),

            const SizedBox(height: 24),

            // [INPUT] Full Name
            TextField(
              decoration: InputDecoration(
                hintText: "Full Name",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // [INPUT] Email
            TextField(
              decoration: InputDecoration(
                hintText: "Email",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // [INPUT] Password
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // [BUTTON] Sign Up
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomePage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary_600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // [NAVIGATION] Go to Login
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginPage()));
              },
              child: const Text(
                "Already have an account? Log in",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary_100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}