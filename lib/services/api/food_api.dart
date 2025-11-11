// lib/services/api/food_api.dart
import 'dart:convert';
import '../../models/food/food_item_model.dart';
import '../api_service.dart';

class FoodApi {
  // ======================================================
  // 🍛 GET ALL FOOD ITEMS
  // ======================================================
  static Future<List<FoodItem>> getFoods() async {
    final response = await ApiService.get('food_menu/food_items/'); // ✅ FIXED ENDPOINT
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load menu: ${response.statusCode} ${response.body}');
    }
  }

  // ======================================================
  // 🍳 CREATE NEW FOOD ITEM
  // ======================================================
  static Future<void> createFood(Map<String, dynamic> foodData) async {
    final response = await ApiService.post('food_menu/food_items/', foodData);
    if (response.statusCode != 201) {
      throw Exception('Failed to create menu item: ${response.statusCode} ${response.body}');
    }
  }

  // ======================================================
  // ✏️ UPDATE FOOD ITEM
  // ======================================================
  static Future<void> updateFood(int id, Map<String, dynamic> foodData) async {
    final response = await ApiService.put('food_menu/food_items/$id/', foodData);
    if (response.statusCode != 200) {
      throw Exception('Failed to update menu item: ${response.statusCode} ${response.body}');
    }
  }

  // ======================================================
  // 🗑️ DELETE FOOD ITEM
  // ======================================================
  static Future<void> deleteFood(int id) async {
    final response = await ApiService.delete('food_menu/food_items/$id/');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete menu item: ${response.statusCode} ${response.body}');
    }
  }
}
