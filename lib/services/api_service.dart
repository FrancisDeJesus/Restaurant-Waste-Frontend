// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ApiService {
  // ======================================================
  // 🌍 BASE URL
  // ======================================================
  static const String baseUrl = "http://127.0.0.1:8000/api/";

  static Uri url(String path) => Uri.parse("$baseUrl$path");

  // ======================================================
  // 🔐 AUTH HEADERS
  // ======================================================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    debugPrint("🔐 Sending token: $token");
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ✅ Public helper to get token anywhere
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // ======================================================
  // 💾 TOKEN MANAGEMENT
  // ======================================================
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<void> saveTokens(String access, String? refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    if (refresh != null) {
      await prefs.setString(_refreshKey, refresh);
    }
    debugPrint("✅ Tokens saved successfully");
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove('driver_id');
    await prefs.remove('driver_name');
    debugPrint("🧹 Tokens and driver info cleared");
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
  // 📡 HTTP METHODS
  // ======================================================
  static Future<http.Response> get(String path) async {
    final headers = await _headers();
    debugPrint("📡 GET → $path");
    return http.get(url(path), headers: headers);
  }

  static Future<http.Response> post(String path, Map body) async {
    final headers = await _headers();
    debugPrint("📡 POST → $path | Body: $body");
    return http.post(url(path), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String path, Map body) async {
    final headers = await _headers();
    debugPrint("📡 PUT → $path | Body: $body");
    return http.put(url(path), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> patch(String path, Map body) async {
    final headers = await _headers();
    debugPrint("📡 PATCH → $path | Body: $body");
    return http.patch(url(path), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    final headers = await _headers();
    debugPrint("📡 DELETE → $path");
    return http.delete(url(path), headers: headers);
  }
}
