import 'package:restaurant_frontend/models/food/ingredient_model.dart';

class FoodItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final int shelfLifeDays;
  final DateTime createdAt;
  final DateTime expirationDate;
  final bool isSpoiled;
  final List<Ingredient> ingredients;

  FoodItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    required this.shelfLifeDays,
    required this.createdAt,
    required this.expirationDate,
    required this.isSpoiled,
    required this.ingredients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      category: json['category'] ?? '',
      shelfLifeDays: json['shelf_life_days'] ?? 3,

      // ✅ Defensive null-safe DateTime parsing
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),

      expirationDate: json['expiration_date'] != null
          ? DateTime.tryParse(json['expiration_date']) ??
              DateTime.now().add(Duration(days: json['shelf_life_days'] ?? 3))
          : DateTime.now().add(Duration(days: json['shelf_life_days'] ?? 3)),

      isSpoiled: json['is_spoiled'] ?? false,

      ingredients: (json['ingredients'] as List? ?? [])
          .map((i) => Ingredient.fromJson(i))
          .toList(),
    );
  }
}
