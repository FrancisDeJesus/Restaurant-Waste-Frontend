// lib/services/api/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuthApi {
  // ======================================================
  // 🧾 SIGNUP — Register new restaurant owner
  // ======================================================
  static Future<void> signup({
    required String username,
    required String email,
    required String password,
    required String restaurantName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}accounts/register/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'restaurant_name': restaurantName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode != 201) {
      try {
        final error = jsonDecode(response.body);
        throw Exception('Signup failed: ${error.toString()}');
      } catch (_) {
        throw Exception('Signup failed (status ${response.statusCode})');
      }
    }
  }

  // ======================================================
  // 🔑 LOGIN — Restaurant / Employee (default)
  // ======================================================
  static Future<bool> loginUser(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}accounts/token/"), // ✅ updated
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'];
        final refresh = data['refresh'];

        if (access != null && refresh != null) {
          await ApiService.saveTokens(access, refresh);
          return true;
        } else {
          throw Exception('Missing access or refresh token.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid username or password.');
      } else {
        throw Exception('Login failed (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ======================================================
  // 🚪 LOGOUT — Clear stored tokens
  // ======================================================
  static Future<void> logout() async {
    await ApiService.clearTokens();
  }


  // ======================================================
  // 🚚 DRIVER LOGIN — Obtain JWT from /api/accounts/driver/token/
  // ======================================================
  static Future<Map<String, dynamic>?> loginDriver(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}accounts/driver/token/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      debugPrint('🚛 Driver login response: ${response.statusCode}');
      debugPrint('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'];
        final refresh = data['refresh'];
        final driverId = data['driver_id'];
        final fullName = data['full_name'];

        if (access != null && refresh != null) {
          await ApiService.saveTokens(access, refresh);
          await ApiService.saveDriverInfo(driverId, fullName);
          debugPrint('✅ Driver login successful → $fullName (ID: $driverId)');
          return data; // 🔁 return all info for navigation
        }
      }

      debugPrint('❌ Driver login failed with code ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('⚠️ Driver login error: $e');
      return null;
    }
  }

  // ======================================================
  // 👤 PROFILE — Fetch current restaurant/employee/driver info
  // ======================================================
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.get("accounts/me/");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("👤 Profile data: $data");

      // Normalize role field
      if (data['role'] == null) {
        if (data['driver_id'] != null || data['is_driver'] == true) {
          data['role'] = 'driver';
        } else if (data['employee_id'] != null) {
          data['role'] = 'employee';
        } else {
          data['role'] = 'restaurant';
        }
      }

      return data;
    } else if (response.statusCode == 401) {
      await ApiService.clearTokens();
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to fetch profile (${response.statusCode})');
    }
  }
}
