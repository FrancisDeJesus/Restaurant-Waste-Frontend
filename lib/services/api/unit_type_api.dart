// lib/services/api/unit_type_api.dart
import 'dart:convert';
import '../api_service.dart';
import '../../models/food/unit_type_model.dart';

class UnitTypeApi {
  static Future<List<UnitType>> getUnitTypes() async {
    final response = await ApiService.get('food_menu/unit_types/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => UnitType.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load unit types');
    }
  }

  static Future<void> createUnitType(Map<String, dynamic> body) async {
    final response = await ApiService.post('food_menu/unit_types/', body);
    if (response.statusCode != 201) {
      throw Exception('Failed to create unit type');
    }
  }

  static Future<void> deleteUnitType(int id) async {
    final response = await ApiService.delete('food_menu/unit_types/$id/');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete unit type');
    }
  }
}
