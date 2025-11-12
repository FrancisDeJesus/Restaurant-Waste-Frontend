// lib/services/api/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../api_service.dart';

// 🔥 Firebase & Google Sign-In imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        Uri.parse("${ApiService.baseUrl}accounts/token/"),
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
  // 🚚 DRIVER LOGIN — Obtain JWT from /api/accounts/driver/token/
  // ======================================================
  static Future<Map<String, dynamic>?> loginDriver(
      String username, String password) async {
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
          return data;
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

  // ======================================================
  // 🚪 LOGOUT — Clear stored tokens
  // ======================================================
  static Future<void> logout() async {
    await ApiService.clearTokens();
    await signOutFromGoogle();
  }

  // ======================================================
  // 🔐 GOOGLE SIGN-IN (Firebase Integration + Django JWT Exchange)
  // ======================================================
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId:
            "894883712149-c0f4p7r1b1sb2d10877tcg1p22nmaltn.apps.googleusercontent.com",
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled login

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 🔥 Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception("Google user not found.");

      debugPrint("✅ Google Sign-In success: ${user.email}");

      // ======================================================
      // 🔁 Exchange Firebase Token with Django JWT
      // ======================================================
      final firebaseToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}accounts/google-auth/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"firebase_token": firebaseToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'];
        final refresh = data['refresh'];

        if (access != null) {
          await ApiService.saveTokens(access, refresh);
          debugPrint("🎟️ JWT tokens saved from Google login.");
        } else {
          debugPrint("⚠️ No JWT returned from backend.");
        }
      } else {
        debugPrint(
            "⚠️ Django token exchange failed: ${response.statusCode} - ${response.body}");
      }

      return userCredential;
    } catch (e) {
      debugPrint("❌ Google Sign-In failed: $e");
      rethrow;
    }
  }

  // ======================================================
  // 🔓 SIGN OUT (Google + Firebase)
  // ======================================================
  static Future<void> signOutFromGoogle() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      debugPrint("👋 Google user signed out successfully.");
    } catch (e) {
      debugPrint("⚠️ Google sign-out failed: $e");
    }
  }
}
