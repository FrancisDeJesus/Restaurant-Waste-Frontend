import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../screens/trash_pickups/trash_pickup_model.dart';
import '../api_service.dart';

class TrashPickupsApi {
  static const String basePath = "trash_pickups/";

  static Future<List<TrashPickup>> getAll() async {
    final response = await ApiService.get(basePath);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch trash pickups");
    }
  }

  // 🔹 Fetch only completed & cancelled pickups (History)
  static Future<List<TrashPickup>> getHistory() async {
    final response = await ApiService.get("${basePath}history/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch pickup history");
    }
  }

  static Future<void> create(TrashPickup pickup) async {
    final response = await ApiService.post(basePath, pickup.toJson());
    if (response.statusCode != 201) {
      throw Exception("Failed to create trash pickup");
    }
  }

  static Future<void> update(TrashPickup pickup) async {
    final response = await ApiService.put("$basePath${pickup.id}/", pickup.toJson());
    if (response.statusCode != 200) {
      throw Exception("Failed to update trash pickup");
    }
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete("$basePath$id/");
    if (response.statusCode != 204) {
      throw Exception("Failed to delete trash pickup");
    }
  }

  // ✅ NEW: Cancel a pickup (PATCH request)
  static Future<void> cancel(int id) async {
    final response = await ApiService.patch("$basePath$id/cancel/", {});
    if (response.statusCode != 200) {
      throw Exception("Failed to cancel pickup (${response.statusCode})");
    }
  }
}
