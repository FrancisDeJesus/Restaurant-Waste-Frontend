// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class ApiService {
  // ======================================================
  // 🌍 BASE URL (Auto-detect environment)
  // ======================================================
  // For emulator → 10.0.2.2 | For physical device → use your local IP
  static const String _localBase = "http://10.0.2.2:8000/api/";
  static const String _webBase = "http://127.0.0.1:8000/api/";

  static String get baseUrl => kIsWeb ? _webBase : _localBase;
  static Uri url(String path) => Uri.parse("$baseUrl$path");

  // ======================================================
  // 🔑 TOKEN STORAGE KEYS
  // ======================================================
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _googleKey = 'google_token'; // ✅ for Google sign-ins

  // ======================================================
  // 💾 TOKEN MANAGEMENT
  // ======================================================
  static Future<void> saveTokens(String access, [String? refresh]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    if (refresh != null) await prefs.setString(_refreshKey, refresh);
    debugPrint("✅ Tokens saved successfully: $access");
  }

  static Future<void> saveGoogleToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleKey, token);
    debugPrint("✅ Google token saved: $token");
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_googleKey);
    await prefs.remove('driver_id');
    await prefs.remove('driver_name');
    debugPrint("🧹 All tokens cleared");
  }

  // ======================================================
  // 🔐 HEADER BUILDER
  // ======================================================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessKey) ??
        prefs.getString(_googleKey); // ✅ fallback for Google
    debugPrint("🔐 Sending token: $token");

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Public helper (optional)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey) ?? prefs.getString(_googleKey);
  }

  // ======================================================
  // 🚚 DRIVER INFO HELPERS
  // ======================================================
  static Future<void> saveDriverInfo(int? driverId, String? fullName) async {
    final prefs = await SharedPreferences.getInstance();
    if (driverId != null) await prefs.setInt('driver_id', driverId);
    if (fullName != null) await prefs.setString('driver_name', fullName);
    debugPrint("🚛 Driver info saved: ID=$driverId, Name=$fullName");
  }

  static Future<int?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('driver_id');
  }

  static Future<String?> getDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_name');
  }

  // ======================================================
  // 🧾 BODY ENCODER
  // ======================================================
  static dynamic _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      debugPrint("⚠️ Failed to encode body to JSON, sending raw.");
      return body;
    }
  }

  // ======================================================
  // 📡 HTTP METHODS (ALL INCLUDE AUTH HEADERS)
  // ======================================================
  static Future<http.Response> get(String path) async {
    final headers = await _headers();
    debugPrint("📡 GET → $path");
    final response = await http.get(url(path), headers: headers);
    _logResponse(path, response);
    return response;
  }

  static Future<http.Response> post(String path, dynamic body) async {
    final headers = await _headers();
    debugPrint("📡 POST → $path | Body: $body");
    final response =
        await http.post(url(path), headers: headers, body: _encodeBody(body));
    _logResponse(path, response);
    return response;
  }

  static Future<http.Response> put(String path, dynamic body) async {
    final headers = await _headers();
    debugPrint("📡 PUT → $path | Body: $body");
    final response =
        await http.put(url(path), headers: headers, body: _encodeBody(body));
    _logResponse(path, response);
    return response;
  }

  static Future<http.Response> patch(String path, dynamic body) async {
    final headers = await _headers();
    debugPrint("📡 PATCH → $path | Body: $body");
    final response =
        await http.patch(url(path), headers: headers, body: _encodeBody(body));
    _logResponse(path, response);
    return response;
  }

  static Future<http.Response> delete(String path) async {
    final headers = await _headers();
    debugPrint("📡 DELETE → $path");
    final response = await http.delete(url(path), headers: headers);
    _logResponse(path, response);
    return response;
  }

  // ======================================================
  // 🧠 LOG RESPONSE
  // ======================================================
  static void _logResponse(String path, http.Response response) {
    debugPrint("🔽 RESPONSE [$path]: ${response.statusCode}");
    debugPrint(response.body);
  }
}
