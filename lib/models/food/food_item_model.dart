class FoodItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final List<FoodIngredient> ingredients;

  FoodItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    required this.ingredients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0,
      category: json['category'],
      ingredients: (json['food_ingredients'] as List? ?? [])
          .map((i) => FoodIngredient.fromJson(i))
          .toList(),
    );
  }
}

// ======================================================
// ✅ Food Ingredient Model (Now includes unit type info)
// ======================================================
class FoodIngredient {
  final int id;
  final int ingredientId;
  final String ingredientName;
  final double quantityUsed;
  final int unitTypeId;
  final String unitTypeName;
  final String unitTypeAbbreviation;

  FoodIngredient({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityUsed,
    required this.unitTypeId,
    required this.unitTypeName,
    required this.unitTypeAbbreviation,
  });

  factory FoodIngredient.fromJson(Map<String, dynamic> json) {
    return FoodIngredient(
      id: json['id'],
      ingredientId: json['ingredient'],
      ingredientName: json['ingredient_name'] ?? '',
      quantityUsed: double.tryParse(json['quantity_used'].toString()) ?? 0,
      unitTypeId: json['unit_type'] ?? 0,
      unitTypeName: json['unit_type_name'] ?? '',
      unitTypeAbbreviation: json['unit_type_abbreviation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient': ingredientId,
      'quantity_used': quantityUsed,
      'unit_type': unitTypeId,
    };
  }
}
