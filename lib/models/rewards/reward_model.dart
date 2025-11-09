class Reward {
  final int? id;
  final String title;
  final String description;
  final int pointsRequired;

  Reward({
    this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsRequired: json['points_required'],
    );
  }
}
