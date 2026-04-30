// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding flow — shown once after a new user registers.
// Collects: full name, display name/username, birthday, and bio.
// Email & password are already stored from signup.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileOnboarding extends StatefulWidget {
  const ProfileOnboarding({super.key});

  @override
  State<ProfileOnboarding> createState() => _ProfileOnboardingState();
}

class _ProfileOnboardingState extends State<ProfileOnboarding> {
  // [CONTROLLERS]
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // [STATE]
  int _currentStep = 0; // 0 = name, 1 = username, 2 = birthday+bio
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _birthdayController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // [HELPER] Birthday picker
  // ─────────────────────────────────────────────
  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary_600,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  // ─────────────────────────────────────────────
  // [ACTION] Validate current step and advance
  // ─────────────────────────────────────────────
  void _nextStep() {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name.');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        setState(() => _errorMessage = 'Please enter a username.');
        return;
      }
      if (username.contains(' ')) {
        setState(() => _errorMessage = 'Username cannot contain spaces.');
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  // ─────────────────────────────────────────────
  // [ACTION] Finish onboarding — save to Hive
  // ─────────────────────────────────────────────
  Future<void> _finishOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await DatabaseHelper().updateUserProfile({
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'birthday': _birthdayController.text,
      'bio': _bioController.text.trim(),
      'onboardingComplete': true,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacementNamed(context, '/');
  }

  // ─────────────────────────────────────────────
  // [UI] Step indicator dots
  // ─────────────────────────────────────────────
  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? AppColors.primary_600 : AppColors.primary_200,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // [UI] Step 0 — Full Name
  // ─────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your name?",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.text_800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "This is how you'll appear to others.",
          style: TextStyle(
            fontFamily: "Nunito",
            fontSize: 15,
            color: AppColors.text_500,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: "Full Name",
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // [UI] Step 1 — Username
  // ─────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pick a username",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.text_800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Choose something unique — no spaces allowed.",
          style: TextStyle(
            fontFamily: "Nunito",
            fontSize: 15,
            color: AppColors.text_500,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: "Username",
            prefixIcon: const Icon(Icons.alternate_email),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // [UI] Step 2 — Birthday & Bio
  // ─────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "A little about you",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.text_800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Both fields are optional — skip if you prefer.",
          style: TextStyle(
            fontFamily: "Nunito",
            fontSize: 15,
            color: AppColors.text_500,
          ),
        ),
        const SizedBox(height: 28),

        // Birthday
        TextField(
          controller: _birthdayController,
          readOnly: true,
          onTap: _pickBirthday,
          decoration: InputDecoration(
            hintText: "Birthday (MM/DD/YYYY)",
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bio
        TextField(
          controller: _bioController,
          maxLines: 3,
          maxLength: 150,
          decoration: InputDecoration(
            hintText: "Short bio (optional)",
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(Icons.notes_outlined),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [HEADER] Step dots + Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepDots(),
                  // Skip only shows on the last step
                  if (_currentStep == 2)
                    TextButton(
                      onPressed: _isLoading ? null : _finishOnboarding,
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 14,
                          color: AppColors.text_400,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 56),
                ],
              ),

              const SizedBox(height: 40),

              // [CONTENT] Current step
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentStep),
                      child: _currentStep == 0
                          ? _buildStep0()
                          : _currentStep == 1
                              ? _buildStep1()
                              : _buildStep2(),
                    ),
                  ),
                ),
              ),

              // [ERROR]
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB3B3)),
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
              ],

              const SizedBox(height: 24),

              // [BUTTONS] Back / Next / Finish
              Row(
                children: [
                  // Back button (hidden on first step)
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _currentStep = _currentStep - 1),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary_600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Back",
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary_600,
                          ),
                        ),
                      ),
                    ),

                  if (_currentStep > 0) const SizedBox(width: 12),

                  // Next / Finish button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_currentStep < 2 ? _nextStep : _finishOnboarding),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary_600,
                        disabledBackgroundColor:
                            AppColors.primary_600.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                          : Text(
                              _currentStep < 2 ? "Next" : "Let's Go!",
                              style: const TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}