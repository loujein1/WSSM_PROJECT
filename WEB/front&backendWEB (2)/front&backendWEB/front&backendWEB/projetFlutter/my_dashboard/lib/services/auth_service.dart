import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class AuthService {
  final String baseUrl = "http://localhost:3000/users"; // ✅ Adjust API URL

  // ✅ Register New User
  Future<Map<String, dynamic>> registerUser(String email, String username, String password) async {
    try {
      print('Sending registration request to: $baseUrl/signup');
      print('Registration payload: {"email": "$email", "username": "$username", "password": "***"}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "username": username, "password": password}),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {"success": true, "message": "Registration successful!"};
      } else {
        var errorMsg = "Failed to register";
        try {
          var responseBody = jsonDecode(response.body);
          errorMsg = responseBody["message"] ?? errorMsg;
          if (responseBody["error"] != null) {
            errorMsg = responseBody["error"];
          }
        } catch (e) {
          print('Error parsing registration response: $e');
        }
        return {"success": false, "message": errorMsg};
      }
    } catch (e) {
      print('Exception during registration: $e');
      return {"success": false, "message": "Error during signup: $e"};
    }
  }

  // ✅ Login User and Store Token & User Data
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('Sending login request to: $baseUrl/login');
      print('Login payload: {"email": "$email", "password": "***"}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          var data = jsonDecode(response.body);
          String token = data["token"] ?? "";
          Map<String, dynamic> userData = data["user"] ?? {}; 
          
          if (token.isEmpty) {
            print("Warning: Empty token received from server");
          }
          
          print("Token received: ${token.substring(0, math.min(10, token.length))}...");
          print("User data received: $userData");

          await _saveToken(token);
          await _saveUserInfo(userData);

          return {"success": true, "message": "Login successful!", "token": token, "user": userData};
        } catch (e) {
          print("Error processing login response: $e");
          return {"success": false, "message": "Error processing login response: $e"};
        }
      } else {
        var errorMsg = "Login failed";
        try {
          var responseBody = jsonDecode(response.body);
          errorMsg = responseBody["message"] ?? errorMsg;
          if (responseBody["error"] != null) {
            errorMsg = responseBody["error"];
          }
        } catch (e) {
          print('Error parsing login response: $e');
        }
        return {"success": false, "message": errorMsg};
      }
    } catch (e) {
      print('Exception during login: $e');
      return {"success": false, "message": "Error during login: $e"};
    }
  }

  // ✅ Logout User (Clear Token & User Info)
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_info");
  }

  // ✅ Check if User is Logged In
  static Future<bool> isLoggedIn() async {
    String? token = await _getToken();
    return token != null;
  }

  // ✅ Retrieve Stored User Info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfo = prefs.getString("user_info");

    if (userInfo != null) {
      return jsonDecode(userInfo);
    }
    return null;
  }

  // ✅ Check if User Can Access Admin Panel
  static Future<bool> canAccessAdminPanel() async {
    Map<String, dynamic>? user = await getCurrentUser();
    return user?["role"] == "admin"; // ✅ Allow access only if user role is 'admin'
  }

  // ✅ Save Token
  static Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
  }

  // ✅ Save User Info
  static Future<void> _saveUserInfo(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_info", jsonEncode(userData));
  }

  // ✅ Retrieve Stored Token
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // ✅ Update User Profile
  static Future<Map<String, dynamic>> updateProfile(String username, String email, String? password) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Not authenticated"};
      }

      Map<String, dynamic>? currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {"success": false, "message": "User data not found"};
      }

      String userId = currentUser["id"];
      final baseUrl = "http://localhost:3000/users";

      // Create update data object
      Map<String, dynamic> updateData = {
        "username": username,
        "email": email,
      };

      // Only include password if it's not empty
      if (password != null && password.isNotEmpty) {
        updateData["password"] = password;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        
        // Update stored user info
        Map<String, dynamic> updatedUserData = {
          ...currentUser,
          "username": username,
          "email": email,
        };
        await _saveUserInfo(updatedUserData);
        
        return {"success": true, "message": "Profile updated successfully", "user": updatedUserData};
      } else {
        return {"success": false, "message": jsonDecode(response.body)["message"] ?? "Failed to update profile"};
      }
    } catch (e) {
      return {"success": false, "message": "Error updating profile: $e"};
    }
  }

  // ✅ Delete User Account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Not authenticated"};
      }

      Map<String, dynamic>? currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {"success": false, "message": "User data not found"};
      }

      String userId = currentUser["id"];
      final baseUrl = "http://localhost:3000/users";

      final response = await http.delete(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        // Clear user data and token
        await logout();
        return {"success": true, "message": "Account deleted successfully"};
      } else {
        return {"success": false, "message": jsonDecode(response.body)["message"] ?? "Failed to delete account"};
      }
    } catch (e) {
      return {"success": false, "message": "Error deleting account: $e"};
    }
  }
}
