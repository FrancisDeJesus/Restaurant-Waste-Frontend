import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../screens/trash_pickups/trash_pickup_model.dart';
import '../api_service.dart';

class TrashPickupsApi {
  static const String basePath = "trash_pickups/";

  // =========================================================
  // 📦 GET ALL PICKUPS (active for restaurant or driver)
  // =========================================================
  static Future<List<TrashPickup>> getAll() async {
    final response = await ApiService.get(basePath);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch trash pickups");
    }
  }

  // =========================================================
  // 🕓 GET PICKUP HISTORY (completed + cancelled)
  // =========================================================
  static Future<List<TrashPickup>> getHistory() async {
    final response = await ApiService.get("${basePath}history/");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TrashPickup.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch pickup history");
    }
  }

  // =========================================================
  // 🧱 CREATE PICKUP
  // =========================================================
  static Future<void> create(
    TrashPickup pickup, {
    List<int>? proofImageBytes,
    String? proofImageFilename,
  }) async {
    if (proofImageBytes == null) {
      final response = await ApiService.post(basePath, pickup.toJson());
      if (response.statusCode != 201) {
        throw Exception("Failed to create trash pickup (${response.statusCode})");
      }
      return;
    }

    final request = http.MultipartRequest('POST', ApiService.url(basePath));
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final data = pickup.toJson();
    data.forEach((key, value) {
      request.fields[key] = value?.toString() ?? '';
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'proof_photo',
        proofImageBytes,
        filename: proofImageFilename ?? 'waste-proof.jpg',
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception(
        "Failed to create trash pickup (${response.statusCode}): ${response.body}",
      );
    }
  }

  // =========================================================
  // ✏️ UPDATE PICKUP
  // =========================================================
  static Future<void> update(TrashPickup pickup) async {
    final response = await ApiService.put("$basePath${pickup.id}/", pickup.toJson());
    if (response.statusCode != 200) {
      throw Exception("Failed to update trash pickup (${response.statusCode})");
    }
  }

  // =========================================================
  // ❌ DELETE PICKUP
  // =========================================================
  static Future<void> delete(int id) async {
    final response = await ApiService.delete("$basePath$id/");
    if (response.statusCode != 204) {
      throw Exception("Failed to delete trash pickup (${response.statusCode})");
    }
  }

  // =========================================================
  // 🚫 CANCEL PICKUP
  // =========================================================
  static Future<void> cancel(int id) async {
    final response = await ApiService.patch("$basePath$id/cancel/", {});
    if (response.statusCode != 200) {
      throw Exception("Failed to cancel pickup (${response.statusCode})");
    }
  }

  // =========================================================
  // ♻️ REOPEN CANCELLED PICKUP
  // =========================================================
  static Future<void> reopen(int id) async {
    final response = await ApiService.patch("$basePath$id/reopen/", {});
    if (response.statusCode != 200) {
      throw Exception("Failed to reopen pickup (${response.statusCode})");
    }
  }

  // =========================================================
  // 🚚 DRIVER ACTIONS
  // =========================================================

  /// 🟢 Accept a pickup
  static Future<void> accept(int id) async {
    final response = await ApiService.patch("$basePath$id/accept/", {});
    if (response.statusCode != 200) {
      throw Exception("Failed to accept pickup (${response.statusCode})");
    }
  }

  /// 🟡 Start a pickup
  static Future<void> start(int id) async {
    final response = await ApiService.patch("$basePath$id/start/", {});
    if (response.statusCode != 200) {
      throw Exception("Failed to start pickup (${response.statusCode})");
    }
  }

  /// 🟣 Complete a pickup — returns points awarded 🎉
  static Future<Map<String, dynamic>> complete(int id) async {
    final response = await ApiService.patch("$basePath$id/complete/", {});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "message": data["message"] ?? "Pickup completed successfully.",
        "points_awarded": data["points_awarded"] ?? 0,
      };
    } else {
      throw Exception("Failed to complete pickup (${response.statusCode})");
    }
  }
}
