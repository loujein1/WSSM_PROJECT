import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/water_usage.dart';

class ApiService {
  // Try both localhost formats to ensure connection works
  final List<String> baseUrls = [
    "http://127.0.0.1:5000",  // Primary URL
    "http://localhost:5000",  // Fallback URL 1
    "http://192.168.1.4:5000" // Fallback URL 2 (local network IP)
  ];
  
  // Helper method to try multiple URLs
  Future<http.Response> _tryUrls(String path, {Map<String, String>? headers}) async {
    Exception? lastException;
    
    for (final baseUrl in baseUrls) {
      try {
        final url = Uri.parse('$baseUrl$path');
        print("Trying URL: $url");
        
        final response = await http.get(
          url,
          headers: headers ?? {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        ).timeout(const Duration(seconds: 5));
        
        print("Response from $url: ${response.statusCode}");
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
      } catch (e) {
        print("Error with URL $baseUrl$path: $e");
        lastException = Exception(e.toString());
        continue;
      }
    }
    
    throw lastException ?? Exception("All URLs failed");
  }

  Future<List<WaterUsage>> fetchWaterUsage() async {
    try {
      final response = await _tryUrls('/water-usage');
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => WaterUsage.fromJson(data)).toList();
    } catch (e) {
      print("Error fetching water usage: $e");
      throw Exception("Failed to load water usage data: $e");
    }
  }

  Future<Map<String, dynamic>> fetchUsageSummary() async {
    try {
      final response = await _tryUrls('/water-usage/summary');
      return json.decode(response.body);
    } catch (e) {
      print("Error fetching usage summary: $e");
      throw Exception("Failed to load usage summary: $e");
    }
  }

  Future<double> fetchUsageByDate(String date) async {
    try {
      final response = await _tryUrls('/water-usage/by-date?date=$date');
      return (json.decode(response.body)['usage'] ?? 0).toDouble();
    } catch (e) {
      print("Error fetching usage by date: $e"); 
      throw Exception("Failed to load usage for date: $e");
    }
  }
  
  // Check if server is available
  Future<bool> checkServerAvailable() async {
    for (final baseUrl in baseUrls) {
      try {
        print("Checking server at $baseUrl");
        final response = await http.get(
          Uri.parse(baseUrl),
          headers: {
            'Access-Control-Allow-Origin': '*',
          },
        ).timeout(const Duration(seconds: 3));
        
        print("Server check response: ${response.statusCode}");
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
      } catch (e) {
        print("Server check error for $baseUrl: $e");
        // Try the test endpoint specifically
        try {
          final testResponse = await http.get(
            Uri.parse('$baseUrl/test'),
            headers: {
              'Access-Control-Allow-Origin': '*',
            },
          ).timeout(const Duration(seconds: 3));
          
          print("Test endpoint check: ${testResponse.statusCode}");
          if (testResponse.statusCode == 200) {
            return true;
          }
        } catch (testError) {
          print("Test endpoint error: $testError");
        }
      }
    }
    return false;
  }
  
  // Generate chart directly and get available chart paths
  Future<List<String>> generateAndGetChartPaths() async {
    for (final baseUrl in baseUrls) {
      try {
        print("Generating charts using $baseUrl");
        
        // Try to generate charts
        final genResponse = await http.get(
          Uri.parse('$baseUrl/generate-charts'),
          headers: {
            'Access-Control-Allow-Origin': '*',
          }
        ).timeout(const Duration(seconds: 8));
        
        print("Generate charts response: ${genResponse.statusCode}");
        
        if (genResponse.statusCode == 200) {
          // Try to get chart paths
          try {
            final pathsResponse = await http.get(
              Uri.parse('$baseUrl/available-charts'),
              headers: {
                'Access-Control-Allow-Origin': '*',
              }
            ).timeout(const Duration(seconds: 3));
            
            if (pathsResponse.statusCode == 200) {
              List<dynamic> paths = json.decode(pathsResponse.body);
              print("Got chart paths: $paths");
              return paths.map((p) => p.toString()).toList();
            }
          } catch (e) {
            print("Error fetching chart paths: $e");
          }
          
          // Default fallback (don't use '/chart/' prefix here)
          return ["chart1"]; 
        }
      } catch (e) {
        print("Chart generation error with $baseUrl: $e");
      }
    }
    
    print("Could not generate charts");
    return ["chart1"]; // Default fallback
  }
}
