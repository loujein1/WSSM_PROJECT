import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static final String baseUrl = "http://localhost:3000"; // Same base URL as auth service

  // Helper method to get the token using SharedPreferences directly
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // Fetch all users from the database
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Not authenticated", "users": []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return {
          "success": true, 
          "message": "Users fetched successfully", 
          "users": data is List ? data : (data['users'] ?? [])
        };
      } else {
        return {
          "success": false, 
          "message": jsonDecode(response.body)["message"] ?? "Failed to fetch users",
          "users": []
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error fetching users: $e", "users": []};
    }
  }

  // Update user role (promote/demote admin)
  static Future<Map<String, dynamic>> updateUserRole(String userId, String newRole) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Not authenticated"};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/role'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"role": newRole}),
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "User role updated successfully"};
      } else {
        return {"success": false, "message": jsonDecode(response.body)["message"] ?? "Failed to update user role"};
      }
    } catch (e) {
      return {"success": false, "message": "Error updating user role: $e"};
    }
  }

  // Delete a user (admin only)
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {"success": false, "message": "Not authenticated"};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "User deleted successfully"};
      } else {
        return {"success": false, "message": jsonDecode(response.body)["message"] ?? "Failed to delete user"};
      }
    } catch (e) {
      return {"success": false, "message": "Error deleting user: $e"};
    }
  }
} 