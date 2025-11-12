// lib/services/api/analytics_api.dart
import 'dart:convert';
import '../../models/analytics/volume_analytics_model.dart';
import '../api_service.dart'; // ✅ your base URL & token helpers

class AnalyticsApi {
  // ============================================================
  // 📊 GET WASTE VOLUME ANALYTICS
  // ============================================================
  static Future<VolumeAnalytics> getVolumeAnalytics() async {
    try {
      final response = await ApiService.get('analytics/volume/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VolumeAnalytics.fromJson(data);
      } else {
        throw Exception(
          'Failed to load analytics: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error loading analytics: $e');
    }
  }

  // ============================================================
  // ♻️ GET TODAY’S WASTE SUMMARY
  // ============================================================
  static Future<double> getTodayWaste() async {
    try {
      final response = await ApiService.get('analytics/today/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // returns total_kg from backend, defaults to 0
        return (data['total_kg'] ?? 0).toDouble();
      } else {
        throw Exception(
          'Failed to load today’s waste: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching today’s waste: $e');
    }
  }

  // ============================================================
  // 💡 GET RESTAURANT EFFICIENCY SCORE
  // ============================================================
  static Future<double> getEfficiencyScore() async {
    try {
      final response = await ApiService.get('analytics/efficiency/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // returns efficiency_score from backend, defaults to 0
        return (data['efficiency_score'] ?? 0).toDouble();
      } else {
        throw Exception(
          'Failed to load efficiency score: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching efficiency score: $e');
    }
  }
}
