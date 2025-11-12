class Ingredient {
  final int id;
  final String name;
  final double quantity;
  final int unitTypeId;
  final String unitTypeName;
  final String unitTypeAbbreviation;

  Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitTypeId,
    required this.unitTypeName,
    required this.unitTypeAbbreviation,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? 0,
      name: json['ingredient_name'] ?? json['name'] ?? 'Unknown',
      quantity: (json['quantity_used'] ?? json['quantity'] ?? 0).toDouble(),
      unitTypeId: json['unit_type'] ?? 0,
      unitTypeName: json['unit_type_name'] ?? 'Unknown',
      unitTypeAbbreviation: json['unit_type_abbreviation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_type': unitTypeId,
    };
  }
}
