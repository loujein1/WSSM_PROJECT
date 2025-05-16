import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Add this import


class ApiService {
  final Dio _dio = Dio(BaseOptions(
  baseUrl: 'https://0397-102-159-238-171.ngrok-free.app', // Update this!
));

  Future<Map<String, dynamic>> signup(String email, String username, String password) async {
    try {
      Response response = await _dio.post(
        '/users/signup',
        data: {
          "username": username,
          "email": email,
          "password": password,
        },
      );
      return response.data; // Returns the API response
    } catch (e) {
      print("Error: $e");
      return {"error": "Signup failed"};
    }
  }

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    print("🚀 Sending Login Request...");

    Response response = await _dio.post(
      '/users/login',
      data: {
        "email": email.trim(),
        "password": password.trim(),
      },
    );

    print("✅ API Response: ${response.data}");

    // ✅ Extract the user object safely
    var user = response.data["user"];
    print("🔍 Extracted User Data: $user");

    // ✅ Ensure that user data is properly structured before returning
    return {
      "success": true,
      "token": response.data["token"],
      "email": user?["email"] ?? "No email found",
      "username": user?["username"] ?? "No username found",
      "id": user?["_id"] ?? "No ID found",
    };

  } on DioException catch (e) {
    print("❌ API Error: ${e.response?.statusCode} - ${e.response?.data}");

    return {
      "success": false,
      "error": e.response?.data["message"] ?? "Login failed"
    };
  } catch (e) {
    print("❌ Unexpected Error: $e");
    return {
      "success": false,
      "error": "An unexpected error occurred"
    };
  }
}

 // Fetch materials related to the logged-in user
  Future<List<dynamic>> getUserMaterials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? '';  // Get the logged-in user's ID

      if (userId.isEmpty) {
        throw Exception("User ID is missing");
      }

      Response response = await _dio.get('/materials/user/$userId'); // Assuming the endpoint filters by user ID
      if (response.statusCode == 200) {
        return response.data; // Return list of materials
      } else {
        throw Exception('Failed to load materials');
      }
    } catch (e) {
      print("Error fetching materials: $e");
      throw Exception('Failed to load materials');
    }
  }

//Add material
  Future<void> addMaterial(String name, String description) async {
  try {
    // Get user ID from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';  // Ensure userId is available

    if (userId.isEmpty) {
      throw Exception("User not logged in");
    }

    // Send the material creation request along with the user's ID
    final response = await _dio.post('/materials', data: {
      'name': name,
      'description': description,
      'userId': userId, // Attach the user ID to associate the material with the logged-in user
    });

    if (response.statusCode == 201) {
      print("✅ Material added: ${response.data}");
    } else {
      throw Exception("Failed to add material");
    }
  } catch (e) {
    print("❌ Error adding material: $e");
    throw Exception("Failed to add material");
  }
}



}