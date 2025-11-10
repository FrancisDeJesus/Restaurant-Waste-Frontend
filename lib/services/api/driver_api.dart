// lib/services/api/driver_api.dart
import 'dart:convert';
import '../api_service.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';

class DriverApi {
  // ------------------------------------------------------
  // 👤 Get driver profile (optional helper)
  // ------------------------------------------------------
  static Future<Map<String, dynamic>> getProfile() async {
    return {}; // Not applicable in your design
  }

  // ======================================================
  // 👤 (Admin/Owner) Fetch a driver by ID
  // ======================================================
  static Future<Map<String, dynamic>> getDriver(int driverId) async {
    final resp = await ApiService.get('drivers/$driverId/');
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load driver $driverId: ${resp.body}');
  }

  // ======================================================
  // 🚚 FETCH ASSIGNED PICKUPS (by Driver ID)
  // ======================================================
  static Future<List<TrashPickup>> getAssignedPickups(int driverId) async {
    final response = await ApiService.get('drivers/$driverId/assigned/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load assigned pickups: ${response.body}');
    }
  }

  // ======================================================
  // 📦 FETCH AVAILABLE PICKUPS (pending + unassigned)
  // ======================================================
  static Future<List<TrashPickup>> getAvailablePickups() async {
    final response = await ApiService.get('drivers/available/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load available pickups: ${response.body}');
    }
  }

  // ======================================================
  // 🕓 FETCH DRIVER HISTORY (completed pickups)
  // ======================================================
  static Future<List<TrashPickup>> getHistory(int driverId) async {
    final response = await ApiService.get('drivers/$driverId/history/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load driver history: ${response.body}');
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
    if (response.statusCode != 200) {
      throw Exception('Failed to accept pickup: ${response.body}');
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
    if (response.statusCode != 200) {
      throw Exception('Failed to start pickup: ${response.body}');
    }
  }

  // ======================================================
  // 🏁 COMPLETE PICKUP (✅ FIXED ENDPOINT)
  // ======================================================
  static Future<void> completePickup(int driverId, int pickupId) async {
    // ✅ Call correct endpoint: /api/trash_pickups/{pickupId}/complete/
    final response =
        await ApiService.patch('trash_pickups/$pickupId/complete/', {});

    if (response.statusCode == 200) {
      // Optional debug print
      print('✅ Pickup #$pickupId completed successfully!');
    } else {
      throw Exception('Failed to complete pickup: ${response.body}');
    }
  }
}
