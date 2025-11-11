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
      // ✅ Update the endpoint path to match your Django view route
      final response = await ApiService.get('analytics/volume/');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Parse full backend response (including eligibility)
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
}
