// [IMPORT] Libraries
import 'package:soro/main.dart';
import 'package:flutter/material.dart';

// [IMPORT] Screens
import 'package:soro/screens/home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_200,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // [TITLE] Login
            const Text(
              "Login",
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.text_800,
              ),
            ),

            const SizedBox(height: 24),

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

            // [BUTTON] Login
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
                  "Login",
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

            // [NAVIGATION] Go to Signup
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SignupPage()));
              },
              child: const Text(
                "Don't have an account? Sign up",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary_600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}