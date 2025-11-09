class DonationDrive {
  final int? id;
  final String title;
  final String description;
  final String wasteType;
  final bool isActive;

  DonationDrive({
    this.id,
    required this.title,
    required this.description,
    required this.wasteType,
    required this.isActive,
  });

  factory DonationDrive.fromJson(Map<String, dynamic> json) {
    return DonationDrive(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      wasteType: json['waste_type'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class Donation {
  final int? id;
  final String driveTitle;
  final String wasteType;
  final double weightKg;
  final DateTime donatedAt;

  Donation({
    this.id,
    required this.driveTitle,
    required this.wasteType,
    required this.weightKg,
    required this.donatedAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'],
      driveTitle: json['drive']['title'] ?? 'Unknown',
      wasteType: json['waste_type'] ?? '',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      donatedAt: DateTime.parse(json['donated_at']),
    );
  }
}
