class UnitType {
  final int id;
  final String name;
  final String abbreviation;

  UnitType({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  factory UnitType.fromJson(Map<String, dynamic> json) {
    return UnitType(
      id: json['id'],
      name: json['name'],
      abbreviation: json['abbreviation'] ?? '',
    );
  }
}
