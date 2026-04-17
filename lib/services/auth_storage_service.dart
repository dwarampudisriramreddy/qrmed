import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';
  static const String _keyUserType = 'user_type'; // 'admin', 'college', 'employee'
  static const String _keyCollegeId = 'college_id'; // For college/employee
  static const String _keyCollegeName = 'college_name'; // For employee

  // Save login credentials
  static Future<void> saveLoginCredentials({
    required String email,
    required String password,
    required String userType,
    String? collegeId,
    String? collegeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserPassword, password);
    await prefs.setString(_keyUserType, userType);
    if (collegeId != null) {
      await prefs.setString(_keyCollegeId, collegeId);
    }
    if (collegeName != null) {
      await prefs.setString(_keyCollegeName, collegeName);
    }
  }

  // Get saved login credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyUserEmail);
    final password = prefs.getString(_keyUserPassword);
    final userType = prefs.getString(_keyUserType);
    final collegeId = prefs.getString(_keyCollegeId);
    final collegeName = prefs.getString(_keyCollegeName);

    if (email != null && password != null && userType != null) {
      return {
        'email': email,
        'password': password,
        'userType': userType,
        if (collegeId != null) 'collegeId': collegeId,
        if (collegeName != null) 'collegeName': collegeName,
      };
    }
    return null;
  }

  // Clear saved login credentials
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPassword);
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyCollegeId);
    await prefs.remove(_keyCollegeName);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final credentials = await getSavedCredentials();
    return credentials != null;
  }
}

