import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';

class DriverApi {
  // ======================================================
  // 👤 FETCH DRIVER PROFILE (optional, not used yet)
  // ======================================================
  static Future<Map<String, dynamic>> getProfile() async {
    return {}; // Placeholder for future extension
  }

  // ======================================================
  // 👤 GET DRIVER BY ID
  // ======================================================
  static Future<Map<String, dynamic>> getDriver(int driverId) async {
    final resp = await ApiService.get('drivers/$driverId/');
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('❌ Failed to load driver $driverId: ${resp.body}');
  }

  // ======================================================
  // 🚚 FETCH ASSIGNED PICKUPS (driver-specific)
  // ======================================================
  static Future<List<TrashPickup>> getAssignedPickups(int driverId) async {
    final response = await ApiService.get('drivers/$driverId/assigned/');
    debugPrint("📦 Assigned pickups response: ${response.statusCode}");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception('❌ Failed to load assigned pickups: ${response.body}');
    }
  }

  // ======================================================
  // 📦 FETCH AVAILABLE PICKUPS (pending + unassigned)
  // ======================================================
  static Future<List<TrashPickup>> getAvailablePickups() async {
    // ✅ Correct endpoint: /drivers/available/
    final response = await ApiService.get('drivers/available/');
    debugPrint("📦 Available pickups response: ${response.statusCode}");
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.map((e) => TrashPickup.fromJson(e)).toList();
      } else if (body is Map && body['results'] is List) {
        return (body['results'] as List)
            .map((e) => TrashPickup.fromJson(e))
            .toList();
      } else {
        return [];
      }
    } else if (response.statusCode == 403) {
      throw Exception('🚫 Permission denied. You must log in as a driver.');
    } else if (response.statusCode == 404) {
      throw Exception('⚠️ No available pickups found.');
    } else {
      throw Exception(
          '❌ Failed to load available pickups (${response.statusCode}): ${response.body}');
    }
  }

  // ======================================================
  // 🕓 FETCH DRIVER HISTORY (completed pickups)
  // ======================================================
  static Future<List<TrashPickup>> getHistory(int driverId) async {
    final response = await ApiService.get('drivers/$driverId/history/');
    debugPrint("📜 History response: ${response.statusCode}");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception('❌ Failed to load driver history: ${response.body}');
    }
  }

  // ======================================================
  // ✅ ACCEPT PICKUP (driver-scoped)
  // ======================================================
  static Future<void> acceptPickup(int driverId, int pickupId) async {
    final response = await ApiService.patch(
      'drivers/$driverId/accept/',
      {'pickup_id': pickupId},
    );
    debugPrint("🚀 Accept pickup response: ${response.statusCode}");
    if (response.statusCode != 200) {
      final err = _parseError(response.body);
      throw Exception('❌ Failed to accept pickup: $err');
    }
  }

  // ======================================================
  // 🚀 START PICKUP (driver-scoped)
  // ======================================================
  static Future<void> startPickup(int driverId, int pickupId) async {
    final response = await ApiService.patch(
      'drivers/$driverId/start/',
      {'pickup_id': pickupId},
    );
    debugPrint("▶️ Start pickup response: ${response.statusCode}");
    if (response.statusCode != 200) {
      final err = _parseError(response.body);
      throw Exception('❌ Failed to start pickup: $err');
    }
  }

  // ======================================================
  // 🏁 COMPLETE PICKUP (✅ Fixed endpoint)
  // ======================================================
  static Future<void> completePickup(int driverId, int pickupId, {double? actualWeightKg}) async {
    // ✅ Endpoint: /api/trash_pickups/{pickupId}/complete/
    final payload = <String, dynamic>{};
    if (actualWeightKg != null) {
      payload['actual_weight_kg'] = actualWeightKg;
    }

    final response =
        await ApiService.patch('trash_pickups/$pickupId/complete/', payload);
    debugPrint("✅ Complete pickup response: ${response.statusCode}");
    if (response.statusCode == 200) {
      debugPrint('✅ Pickup #$pickupId completed successfully!');
    } else {
      final err = _parseError(response.body);
      throw Exception('❌ Failed to complete pickup: $err');
    }
  }

  // ======================================================
  // 🧾 ERROR PARSER HELPER
  // ======================================================
  static String _parseError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded.containsKey('detail')) {
        return decoded['detail'];
      }
      if (decoded is Map && decoded.containsKey('error')) {
        return decoded['error'];
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}
