// lib/models/trash_pickup/trash_pickup_model.dart

class TrashPickup {
  final int? id;
  final String wasteType;
  final double weightKg; // Effective weight shown in UI.
  final double? estimatedWeightKg;
  final double? actualWeightKg;
  final String status;
  final String address;
  final double? latitude;   // ✅ added
  final double? longitude;  // ✅ added
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrashPickup({
    this.id,
    required this.wasteType,
    required this.weightKg,
    this.estimatedWeightKg,
    this.actualWeightKg,
    required this.status,
    required this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
  });

  factory TrashPickup.fromJson(Map<String, dynamic> json) {
    // Helper to parse coordinates safely
    double? parseCoord(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Helper to parse weight safely
    double parseWeight(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double? parseNullableWeight(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return TrashPickup(
      id: json['id'],
      wasteType: json['waste_type'] ?? 'Unknown',
      weightKg: parseWeight(
        json['actual_weight_kg'] ?? json['estimated_weight_kg'] ?? json['weight_kg'],
      ),
      estimatedWeightKg: parseNullableWeight(json['estimated_weight_kg']),
      actualWeightKg: parseNullableWeight(json['actual_weight_kg']),
      status: json['status'] ?? 'pending',
      address: json['address'] ?? '',
      latitude: parseCoord(json['latitude']),   // ✅ added
      longitude: parseCoord(json['longitude']), // ✅ added
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'waste_type': wasteType,
      'weight_kg': estimatedWeightKg ?? weightKg,
      'estimated_weight_kg': estimatedWeightKg ?? weightKg,
      if (actualWeightKg != null) 'actual_weight_kg': actualWeightKg,
      'status': status,
      'address': address,
      'latitude': latitude,     // ✅ included in JSON output
      'longitude': longitude,   // ✅ included in JSON output
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
