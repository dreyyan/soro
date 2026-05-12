// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // [STATE]
  bool _isLoading = true;
  bool _isSaving = false;

  // [FORM CONTROLLERS]
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _birthdayController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // [ACTION] Load current user data
  Future<void> _loadUserData() async {
    final user = await DatabaseHelper().getLoggedInUser();
    if (!mounted) return;

    setState(() {
      _isLoading = false;

      _fullNameController = TextEditingController(text: user?['fullName'] ?? '');
      _usernameController = TextEditingController(text: user?['username'] ?? '');
      _bioController = TextEditingController(text: user?['bio'] ?? '');
      _birthdayController = TextEditingController(text: user?['birthday'] ?? '');
    });
  }

  // [ACTION] Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedData = {
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      'birthday': _birthdayController.text.trim(),
    };

    await DatabaseHelper().updateUserProfile(updatedData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.primary_600,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh profile screen
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      appBar: AppBar(
        backgroundColor: AppColors.secondary_50,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text_800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.text_700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value!.trim().isEmpty ? 'Full name is required' : null,
                      ),

                      const SizedBox(height: 20),

                      // Username
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.alternate_email,
                        validator: (value) {
                          if (value!.trim().isEmpty) return 'Username is required';
                          if (value.contains(' ')) return 'Username cannot contain spaces';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Birthday
                      _buildTextField(
                        controller: _birthdayController,
                        label: 'Birthday (YYYY-MM-DD)',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.datetime,
                      ),

                      const SizedBox(height: 20),

                      // Bio
                      _buildTextField(
                        controller: _bioController,
                        label: 'Bio',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary_600,
                            foregroundColor: AppColors.secondary_50,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 1,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // [HELPER] Reusable TextField builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.text_400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.secondary_100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      style: const TextStyle(fontFamily: 'Nunito'),
    );
  }
}