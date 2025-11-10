// lib/services/api/ingredient_api.dart
import 'dart:convert';
import '../../models/food/ingredient_model.dart';
import '../../models/food/ingredient_history_model.dart';
import '../api_service.dart';

class IngredientApi {
  // ------------------------------------------------------------
  // 🧂 GET ALL INGREDIENTS
  // ------------------------------------------------------------
  static Future<List<Ingredient>> getIngredients() async {
    final response = await ApiService.get('food_menu/ingredients/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Ingredient.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load ingredients');
    }
  }

  // ------------------------------------------------------------
  // ➕ CREATE INGREDIENT
  // ------------------------------------------------------------
  static Future<void> createIngredient(Map<String, dynamic> ingredientData) async {
    final response = await ApiService.post('food_menu/ingredients/', ingredientData);
    if (response.statusCode != 201) {
      throw Exception('Failed to add ingredient');
    }
  }

  // ------------------------------------------------------------
  // ✏️ UPDATE INGREDIENT
  // ------------------------------------------------------------
  static Future<void> updateIngredient(int id, Map<String, dynamic> ingredientData) async {
    final response = await ApiService.put('food_menu/ingredients/$id/', ingredientData);
    if (response.statusCode != 200) {
      throw Exception('Failed to update ingredient');
    }
  }

  // ------------------------------------------------------------
  // 🗑 DELETE INGREDIENT
  // ------------------------------------------------------------
  static Future<void> deleteIngredient(int id) async {
    final response = await ApiService.delete('food_menu/ingredients/$id/');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete ingredient');
    }
  }

  // ------------------------------------------------------------
  // 📜 GET INGREDIENT HISTORY
  // ------------------------------------------------------------
  static Future<List<IngredientHistory>> getIngredientHistory(int id) async {
    final response = await ApiService.get('food_menu/ingredients/$id/history/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => IngredientHistory.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load ingredient history');
    }
  }
}
