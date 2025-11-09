// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static const String baseUrl = "http://127.0.0.1:8000/api/";

  static Uri url(String path) => Uri.parse("$baseUrl$path");

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path) async =>
      http.get(url(path), headers: await _headers());

  static Future<http.Response> post(String path, Map body) async =>
      http.post(url(path), headers: await _headers(), body: jsonEncode(body));

  static Future<http.Response> put(String path, Map body) async =>
      http.put(url(path), headers: await _headers(), body: jsonEncode(body));

  static Future<http.Response> patch(String path, Map body) async =>
      http.patch(url(path), headers: await _headers(), body: jsonEncode(body));

  static Future<http.Response> delete(String path) async =>
      http.delete(url(path), headers: await _headers());
}
