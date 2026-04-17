import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_storage_service.dart';
import '../main.dart'; // Import to access AuthWrapper

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut(BuildContext context) async {
    // Navigate to AuthWrapper with "Logging out..." message
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthWrapper(initialMessage: "Logging out..."),
      ),
      (route) => false,
    );

    await _firebaseAuth.signOut();
    // Clear saved login credentials
    await AuthStorageService.clearSavedCredentials();
  }
}
