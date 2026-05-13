// [IMPORT] Libraries
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';
import 'package:soro/widgets/header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // [CONTROLLERS]
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // [STATES]
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // [ACTION] Login
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ! [ERROR] Empty input fields
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await DatabaseHelper().loginUser(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    // * [SUCCESS] Navigate to dashboard
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_200,
      body: SafeArea(
        child: Column(
          children: [
            // [COMPONENT] Header
            const Header(),

            // [SECTION] Login Form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    // * [CONTAINER] Login Form
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.secondary_200,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary_200.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // [UI] Login
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontFamily: "Baloo",
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text_900,
                          ),
                        ),

                        // [UI] Welcome Message
                        const Text(
                          "Welcome back!",
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 15,
                            color: AppColors.text_500,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // [UI] Error Message
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDED),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFFB3B3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 14,
                                color: Color(0xFFCC0000),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // [INPUT] Email
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_800,
                            ),
                            decoration: InputDecoration(
                              hintText: "Email",
                              hintStyle: const TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text_300,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                child: const Icon(Icons.email_outlined),
                              ),
                              filled: true,
                              fillColor: AppColors.secondary_50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // [INPUT] Password
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_800,
                            ),
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: const TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text_300,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                child: const Icon(Icons.lock_outline),
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.secondary_50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // [BUTTON] Login
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary_500,
                              disabledBackgroundColor: AppColors.primary_500.withValues(alpha: 0.6),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text_50,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // [NAVIGATION] Go to Signup
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text_500,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Sign Up",
                                style: const TextStyle(
                                  color: AppColors.primary_500,
                                  fontWeight: FontWeight.w600
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}