import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrashPickup {
  final int? id;
  final String wasteType;          // backend choice key (e.g., "kitchen")
  final String wasteTypeDisplay;   // readable label (e.g., "Kitchen Waste")
  final double weightKg; // Effective weight shown in UI (actual > estimated).
  final double? estimatedWeightKg;
  final double? actualWeightKg;
  final String address;
  final String status;
  final String? proofImageUrl;
  final DateTime scheduleDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrashPickup({
    this.id,
    required this.wasteType,
    required this.wasteTypeDisplay,
    required this.weightKg,
    this.estimatedWeightKg,
    this.actualWeightKg,
    required this.address,
    required this.status,
    this.proofImageUrl,
    required this.scheduleDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Safely parse JSON → Dart model
  factory TrashPickup.fromJson(Map<String, dynamic> json) {
    DateTime safeParse(dynamic value) {
      if (value == null || value.toString().isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    double? safeNullableDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return TrashPickup(
      id: json['id'],
      wasteType: json['waste_type'] ?? 'kitchen',
      wasteTypeDisplay: json['waste_type_display'] ?? 'Kitchen Waste',
      weightKg: safeDouble(
        json['actual_weight_kg'] ?? json['estimated_weight_kg'] ?? json['weight_kg'],
      ),
      estimatedWeightKg: safeNullableDouble(json['estimated_weight_kg']),
      actualWeightKg: safeNullableDouble(json['actual_weight_kg']),
      address: json['address'] ?? 'N/A',
      status: json['status'] ?? 'pending',
      proofImageUrl: (json['proof_photo_url'] ??
              json['proof_photo'] ??
              json['proof_image_url'] ??
              json['proof_image'])
          ?.toString(),
      scheduleDate: safeParse(json['schedule_date']),
      createdAt: safeParse(json['created_at']),
      updatedAt: safeParse(json['updated_at']),
    );
  }

  /// ✅ Convert Dart → JSON (for POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      'waste_type': wasteType,
      'weight_kg': estimatedWeightKg ?? weightKg,
      'estimated_weight_kg': estimatedWeightKg ?? weightKg,
      if (actualWeightKg != null) 'actual_weight_kg': actualWeightKg,
      'address': address,
      'status': status,
      'schedule_date': scheduleDate.toIso8601String(),
    };
  }

  /// 🧾 Formatted readable dates for display
  String get formattedSchedule =>
      DateFormat('MMM d, yyyy • h:mm a').format(scheduleDate);

  String get formattedCreated =>
      DateFormat('MMM d, yyyy • h:mm a').format(createdAt);

  /// 🔹 Readable text for status
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// 🎨 Color-coded status mapping for UI chips
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// ⚙️ Optional: create a copy with updated fields (for editing)
  TrashPickup copyWith({
    int? id,
    String? wasteType,
    String? wasteTypeDisplay,
    double? weightKg,
    double? estimatedWeightKg,
    double? actualWeightKg,
    String? address,
    String? status,
    String? proofImageUrl,
    DateTime? scheduleDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrashPickup(
      id: id ?? this.id,
      wasteType: wasteType ?? this.wasteType,
      wasteTypeDisplay: wasteTypeDisplay ?? this.wasteTypeDisplay,
      weightKg: weightKg ?? this.weightKg,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      address: address ?? this.address,
      status: status ?? this.status,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
