// lib/services/api/food_api.dart
import 'dart:convert';
import '../../models/food/food_item_model.dart';
import '../api_service.dart';

class FoodApi {
  // ======================================================
  // 🍛 GET ALL FOOD ITEMS
  // ======================================================
  static Future<List<FoodItem>> getFoods() async {
    final response = await ApiService.get('food_menu/foods/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load menu');
    }
  }

  // ======================================================
  // 🍳 CREATE NEW FOOD ITEM
  // ======================================================
  static Future<void> createFood(Map<String, dynamic> foodData) async {
    final response = await ApiService.post('food_menu/foods/', foodData);
    if (response.statusCode != 201) {
      throw Exception('Failed to create menu item');
    }
  }

  // UPDATE
  static Future<void> updateFood(int id, Map<String, dynamic> foodData) async {
    final response = await ApiService.put('food_menu/foods/$id/', foodData);
    if (response.statusCode != 200) {
      throw Exception('Failed to update menu item');
    }
  }

  // DELETE
  static Future<void> deleteFood(int id) async {
    final response = await ApiService.delete('food_menu/foods/$id/');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete menu item');
    }
  }





}
