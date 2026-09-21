import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user.dart';
import '../services/user_service.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _shopeeOrange = Color(0xFFEE4D2D);

  @override
  void initState() {
    super.initState();
    _loadFullUserProfile();
  }

  Future<void> _loadFullUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final localUser = await _userService.getUser();
      // Only fetch from DummyJSON if it's a DummyJSON user (id != 0)
      if (localUser.id != 0 && localUser.id != 1) {
        final fullUser = await _userService.fetchFullUserProfile(localUser.id);
        if (!mounted) return;
        setState(() {
          _user = fullUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _user = localUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      final localUser = await _userService.getUser();
      if (!mounted) return;
      setState(() {
        _user = localUser;
        _isLoading = false;
        _errorMessage = 'Could not sync live details. Displaying cached data.';
      });
    }
  }

  // --- Account Management Actions ---

  void _updateUsername() {
    final controller = TextEditingController(text: _user?.username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _userService.updateUsername(controller.text.trim());
                  _loadFullUserProfile(); // Refresh UI
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username updated!')),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _userService.resetPasswordFromCurrentPassword(
                    controller.text.trim(),
                  );
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                      ),
                    );
                } catch (e) {
                  // If the user's session is too old, Firebase throws requires-recent-login
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Action failed. You may need to log out and log back in to verify your identity.',
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteAccount();
                if (mounted)
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/signin',
                    (route) => false,
                  );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Deletion failed. Please log out and log back in before deleting.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Check Login Type
    final bool isFirebaseUser =
        firebase_auth.FirebaseAuth.instance.currentUser != null;
    final String loginType = isFirebaseUser ? 'Firebase Auth' : 'DummyJSON API';

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _shopeeOrange),
      );
    }

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: _shopeeOrange,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Colors.white,
                    backgroundImage: _user?.image.isNotEmpty == true
                        ? NetworkImage(_user!.image)
                        : null,
                    child: _user?.image.isEmpty == true
                        ? Icon(Icons.person, size: 36.sp, color: _shopeeOrange)
                        : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullName.isNotEmpty == true
                              ? _user!.fullName
                              : _user?.username ?? '',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Login Type Indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Account: $loginType',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.w),
                color: isDarkMode
                    ? Colors.orange[900]?.withOpacity(0.3)
                    : Colors.amber[100],
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.orange[200] : Colors.brown,
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            // Section: Personal Information
            _buildSection(
              title: 'Personal Information',
              isDarkMode: isDarkMode,
              tiles: [
                _buildTile(
                  Icons.alternate_email,
                  'Username',
                  _user?.username,
                  isDarkMode,
                ),
                _buildTile(Icons.phone, 'Phone', _user?.phone, isDarkMode),
                _buildTile(
                  Icons.cake,
                  'Age',
                  _user?.age.toString(),
                  isDarkMode,
                ),
                _buildTile(
                  Icons.person_outline,
                  'Gender',
                  _user?.gender.toUpperCase(),
                  isDarkMode,
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Section: Account Management (Only for Firebase Users)
            if (isFirebaseUser)
              _buildSection(
                title: 'Account Management',
                isDarkMode: isDarkMode,
                tiles: [
                  ListTile(
                    leading: Icon(
                      Icons.edit,
                      color: _shopeeOrange,
                      size: 20.sp,
                    ),
                    title: Text(
                      'Update Username',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _updateUsername,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: _shopeeOrange,
                      size: 20.sp,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                      size: 20.sp,
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDarkMode,
    required List<Widget> tiles,
  }) {
    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _buildTile(
    IconData iconData,
    String label,
    String? value,
    bool isDarkMode,
  ) {
    if (value == null || value.trim().isEmpty || value == '0')
      return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: Icon(iconData, color: _shopeeOrange, size: 20.sp),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
