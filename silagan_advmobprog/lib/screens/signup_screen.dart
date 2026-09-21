import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../providers/theme_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color _shopeeOrange = Color(0xFFEE4D2D);

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userService = UserService();

    try {
      // 1. Create account in Firebase
      await userService.createAccount(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Update Firebase Display Name
      await userService.updateUsername(_usernameController.text.trim());

      // 3. Save extra details locally for the Profile screen
      await userService.saveNewUserData(
        fName: _fNameController.text.trim(),
        lName: _lNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        contactNo: _contactController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate to home after successful signup
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString().split(']').last.trim()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey;

    InputDecoration buildDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
        prefixIcon: Icon(icon, color: _shopeeOrange),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _shopeeOrange)),
        border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        backgroundColor: _shopeeOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join us today!',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fNameController,
                        style: TextStyle(color: textColor),
                        decoration: buildDecoration('First Name', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: TextFormField(
                        controller: _lNameController,
                        style: TextStyle(color: textColor),
                        decoration: buildDecoration('Last Name', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: buildDecoration('Age', Icons.cake),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor),
                        decoration: buildDecoration('Contact No.', Icons.phone),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: textColor),
                  decoration: buildDecoration('Username', Icons.alternate_email),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: buildDecoration('Email Address', Icons.email),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor),
                  decoration: buildDecoration('Password', Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Must be at least 6 characters';
                    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
                    return null;
                  },
                ),
                SizedBox(height: 32.h),

                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _shopeeOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h, width: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Sign Up', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}