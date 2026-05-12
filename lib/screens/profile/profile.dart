// [IMPORT] Libraries
import 'package:flutter/material.dart';
// [IMPORT] App
import 'package:soro/main.dart';
// [IMPORT] Database
import 'package:soro/database/database_helper.dart';
import 'package:soro/screens/profile/edit_profile.dart';
import 'package:soro/screens/profile/change_password.dart';
import 'package:soro/screens/profile/settings.dart';

// [CLASS] Profile Page
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // [STATE]
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // [ACTION] Load logged-in user from Hive
  Future<void> _loadUser() async {
    final user = await DatabaseHelper().getLoggedInUser();
    if (mounted) {
      setState(() {
        _userData = user;
        _isLoading = false;
      });
    }
  }

  // [ACTION] Logout
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Log Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseHelper().logoutUser();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  // [HELPER] Build initials avatar when no image
  String _getInitials() {
    final name = _userData?['fullName'] as String? ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // [WIDGET] Individual profile option row
  Widget _buildProfileOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color iconColor = AppColors.primary_500,
    Color textColor = AppColors.text_800,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: AppColors.secondary_100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: AppColors.secondary_300,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: "Nunito",
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: AppColors.text_300,
        ),
        onTap: onTap,
      ),
    );
  }

  // [WIDGET] Info chip (birthday, bio, etc.)
  Widget _buildInfoChip(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.text_400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: "Nunito",
              fontSize: 14,
              color: AppColors.text_400,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: "Nunito",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text_700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (_userData?['fullName'] as String? ?? '').isNotEmpty
        ? _userData!['fullName'] as String
        : 'User';
    final username = _userData?['username'] as String? ?? '';
    final email = _userData?['email'] as String? ?? '';
    final birthday = _userData?['birthday'] as String? ?? '';
    final bio = _userData?['bio'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      // 👇 [HEADER] Exact same placement & structure as Quest
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  // Page title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontFamily: 'Baloo',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text_800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Profile Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary_200,
                          child: Text(
                            _getInitials(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary_700,
                              fontFamily: "Baloo",
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontFamily: "Baloo",
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text_800,
                          ),
                        ),
                        // Username
                        if (username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontSize: 15,
                              color: AppColors.primary_500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Email
                        Text(
                          email,
                          style: const TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 14,
                            color: AppColors.text_400,
                          ),
                        ),
                        // Bio
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.secondary_100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 14,
                                color: AppColors.text_600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        // Extra info chips
                        if (birthday.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoChip(Icons.cake_outlined, "Birthday", birthday),
                        ],
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Account options
                        _buildProfileOption(Icons.edit_outlined, "Edit Profile", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfile()),
                          ).then((updated) {
                            if (updated == true) _loadUser();
                          });
                        }),
                        _buildProfileOption(Icons.lock_outline, "Change Password", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChangePassword()),
                          );
                        }),
                        _buildProfileOption(Icons.settings_outlined, "Settings", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Settings()),
                          );
                        }),
                        const SizedBox(height: 8),
                        // Logout
                        _buildProfileOption(
                          Icons.logout,
                          "Log Out",
                          _handleLogout,
                          iconColor: Colors.red,
                          textColor: Colors.red,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}