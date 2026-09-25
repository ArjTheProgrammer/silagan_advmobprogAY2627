import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  static const String _baseUrl = 'https://dummyjson.com';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  Map<String, dynamic> data = {};

  // ENHANCEMENT 1: FIREBASE AUTH FUNCTIONS

  Future<firebase_auth.UserCredential> signIn(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save minimal session data locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', credential.user?.uid ?? '');
    await prefs.setString('email', credential.user?.email ?? '');

    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount(
    String email,
    String password,
  ) async {
    // 1. Create the user in Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Save the user's data to the Firestore "Users" collection
    if (credential.user != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'email': email,
            // Optional: Create a default first name from the email prefix
            'firstName': email.split('@')[0],
          });
    }

    return credential;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Clears Firebase session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears local tokens
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  Future<void> updateUsername(String newName) async {
    await _auth.currentUser?.updateDisplayName(newName);

    // Sync the new username to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
  }

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear session after deletion
  }

  Future<void> resetPasswordFromCurrentPassword(String newPassword) async {
    // Note: Firebase may require the user to re-authenticate if their session is old.
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // LEGACY/DUMMYJSON FUNCTIONS (For UI display)

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return _auth.currentUser != null || (token != null && token.isNotEmpty);
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 1, // Defaulting to 1 for dummyjson calls
      'username':
          _auth.currentUser?.displayName ?? prefs.getString('username') ?? '',
      'email': _auth.currentUser?.email ?? prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  Future<User> fetchFullUserProfile(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return User.fromJson(json);
    } else {
      throw Exception('Failed to fetch full user profile');
    }
  }

  Future<void> saveNewUserData({
    required String fName,
    required String lName,
    required int age,
    required String contactNo,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', fName);
    await prefs.setString('lastName', lName);
    await prefs.setInt('age', age);
    await prefs.setString('phone', contactNo);
    await prefs.setString('username', username);
  }
}
