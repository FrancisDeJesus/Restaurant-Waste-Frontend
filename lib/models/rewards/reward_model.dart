class Reward {
  final int id;
  final String title;
  final String description;
  final String rewardDetails;
  final int pointsRequired;
  final bool isActive;
  final String availableFrom;
  final String? availableUntil;
  final String createdAt;
  final String updatedAt;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardDetails,
    required this.pointsRequired,
    required this.isActive,
    required this.availableFrom,
    this.availableUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rewardDetails: json['reward_details'] ?? '',
      pointsRequired: json['points_required'] ?? 0,
      isActive: json['is_active'] ?? false,
      availableFrom: json['available_from'] ?? '',
      availableUntil: json['available_until'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "reward_details": rewardDetails,
      "points_required": pointsRequired,
      "is_active": isActive,
      "available_from": availableFrom,
      "available_until": availableUntil,
      "created_at": createdAt,
      "updated_at": updatedAt,
    };
  }
}
