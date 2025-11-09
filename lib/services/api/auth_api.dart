import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class AuthApi {
  // 🔹 SIGNUP — Register new restaurant owner
  static Future<void> signup(
    String username,
    String email,
    String password,
    String restaurantName,
    String address,
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse("${ApiService.baseUrl}accounts/register/");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'restaurant_name': restaurantName,
        'address': address, // ✅ send address to backend
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception('Signup failed: ${error.toString()}');
    }
  }

  // 🔹 LOGIN — Obtain JWT tokens
  static Future<bool> login(String username, String password) async {
    final url = Uri.parse("${ApiService.baseUrl}token/");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      return true;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  // 🔹 PROFILE — Fetch current user info
  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No token found. Please login first.');

    final url = Uri.parse("${ApiService.baseUrl}accounts/me/");
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile (${response.statusCode})');
    }
  }

  // 🔹 LOGOUT — Clear stored tokens
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
