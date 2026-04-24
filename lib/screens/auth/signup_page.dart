// [IMPORT] Libraries
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';
import 'package:soro/widgets/header.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // [CONTROLLERS]
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // [STATES]
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // [ACTION] Signup
  Future<void> _handleSignup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    if (username.length < 3) {
      setState(() => _errorMessage = 'Username must be at least 3 characters.');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await DatabaseHelper().registerUser({
      'username': username,
      'email': email,
      'password': password,
      'onboardingComplete': false,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    await DatabaseHelper().loginUser(email, password);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/onboarding');
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

            // [SECTION] Signup Form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      // * [CONTAINER] Signup Form
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
                          // [UI] Title
                          const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontFamily: "Baloo",
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text_900,
                            ),
                          ),

                          // [UI] Subtitle
                          const Text(
                            "Create your account",
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

                          // [INPUT] Username
                          _buildInputField(
                            controller: _usernameController,
                            hintText: "Username",
                            icon: Icons.person_outline,
                          ),

                          const SizedBox(height: 16),

                          // [INPUT] Email
                          _buildInputField(
                            controller: _emailController,
                            hintText: "Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          // [INPUT] Password
                          _buildInputField(
                            controller: _passwordController,
                            hintText: "Password",
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            onObscureToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),

                          const SizedBox(height: 16),

                          // [INPUT] Confirm Password
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: "Confirm Password",
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirm,
                            onObscureToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),

                          const SizedBox(height: 24),

                          // [BUTTON] Sign Up
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary_500,
                                disabledBackgroundColor:
                                    AppColors.primary_500.withValues(alpha: 0.6),
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
                                      "Sign Up",
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

                          // [NAVIGATION] Go to Login
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text_500,
                              ),
                              children: [
                                const TextSpan(text: "Already have an account? "),
                                TextSpan(
                                  text: "Login",
                                  style: const TextStyle(
                                    color: AppColors.primary_500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.pop(context),
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
            ),
          ],
        ),
      ),
    );
  }

  // [HELPER] Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    VoidCallback? onObscureToggle,
  }) {
    return Container(
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
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: "Nunito",
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.text_800,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: "Nunito",
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text_300,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon),
          ),
          suffixIcon: onObscureToggle != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: onObscureToggle,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.secondary_50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}