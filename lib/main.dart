// [IMPORT] Widgets
import 'package:flutter/material.dart';

// [IMPORT] Screens
import 'package:soro/screens/auth/login_page.dart';
import 'package:soro/screens/auth/signup_page.dart';
import 'package:soro/screens/home_page.dart';
import 'package:soro/screens/cards.dart';
import 'package:soro/screens/quiz.dart';
import 'package:soro/screens/quiz_settings.dart';
import 'package:soro/screens/quiz_start.dart';
import 'package:soro/screens/quest.dart';
import 'package:soro/screens/profile.dart';

// [IMPORT] SQLite
import './database/database_helper.dart';

void main() async {
  // Ensure SQLite is initialized before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local database)
  await DatabaseHelper.init();

  runApp(const MyApp());
}

// [CLASS] Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [CONFIGURATION] Themes & routes
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hide 'default' banner
      theme: ThemeData(),

      // [ROUTES] User
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),         // Login
        '/signup': (_) => const SignupPage(),       // Signup
        '/': (_) => const HomePage(),            // Home Page
        '/cards': (_) => const Cards(),             // Flashcards
        '/quiz': (_) => const Quiz(),               // Quiz: Main
        '/quiz/settings': (_) => const QuizSettings(), // Quiz: Settings
        '/quiz/start': (_) => const QuizStart(),    // Quiz: Start
        '/quest': (_) => const Quest(),             // Quest
        '/profile': (_) => const Profile(),         // Profile
      },
    );
  }
}

// [CLASS] Login Page
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
                  Navigator.pushReplacementNamed(context, '/'); // Go to Home
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
                Navigator.pushNamed(context, '/signup');
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

// [CLASS] Signup Page
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_200,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

            // [INPUT] Name
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
                  Navigator.pushReplacementNamed(context, '/'); // Go to Home
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
                Navigator.pushNamed(context, '/login');
              },
              child: const Text(
                "Already have an account? Log in",
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

// ? [CLASS] Color Palette
class AppColors {
  static const Color primary_50 = Color(0xFFFFF3EE);
  static const Color primary_100 = Color(0xFFFFE4D9);
  static const Color primary_200 = Color(0xFFFFC7B3);
  static const Color primary_300 = Color(0xFFFFA98D);
  static const Color primary_400 = Color(0xFFFF8C67);
  static const Color primary_500 = Color(0xFFFF6B35);
  static const Color primary_600 = Color(0xFFE65F2F);
  static const Color primary_700 = Color(0xFFCC5529);
  static const Color primary_800 = Color(0xFFB34B23);
  static const Color primary_900 = Color(0xFF993F1D);
  static const Color primary_950 = Color(0xFF662914);

  static const Color secondary_50 = Color(0xFFFFFCF6);
  static const Color secondary_100 = Color(0xFFFFF9ED);
  static const Color secondary_200 = Color(0xFFFFF5E1);
  static const Color secondary_300 = Color(0xFFF2E8D3);
  static const Color secondary_400 = Color(0xFFE6DBC5);
  static const Color secondary_500 = Color(0xFFD9CEB7);
  static const Color secondary_600 = Color(0xFFBFB59F);
  static const Color secondary_700 = Color(0xFFA69C87);
  static const Color secondary_800 = Color(0xFF8C846F);
  static const Color secondary_900 = Color(0xFF736B57);
  static const Color secondary_950 = Color(0xFF4D4739);

  static const Color text_50 = Color(0xFFF4F5F7);
  static const Color text_100 = Color(0xFFE6E8EB);
  static const Color text_200 = Color(0xFFC9CDD3);
  static const Color text_300 = Color(0xFFACB2BB);
  static const Color text_400 = Color(0xFF8F97A3);
  static const Color text_500 = Color(0xFF5D6572);
  static const Color text_600 = Color(0xFF535A66);
  static const Color text_700 = Color(0xFF494F5A);
  static const Color text_800 = Color(0xFF3F444E);
  static const Color text_900 = Color(0xFF353942);
  static const Color text_950 = Color(0xFF23262C);

  static const Color green_50 = Color(0xFFF0FDF4);
  static const Color green_100 = Color(0xFFDCFCE7);
  static const Color green_200 = Color(0xFFBBF7D0);
  static const Color green_300 = Color(0xFF86EFAC);
  static const Color green_400 = Color(0xFF4ADE80);
  static const Color green_500 = Color(0xFF22C55E);
  static const Color green_600 = Color(0xFF16A34A);
  static const Color green_700 = Color(0xFF15803D);
  static const Color green_800 = Color(0xFF166534);
  static const Color green_900 = Color(0xFF14532D);
  static const Color green_950 = Color(0xFF0F3D22);
}