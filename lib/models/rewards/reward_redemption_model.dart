import 'reward_model.dart';

class RewardRedemption {
  final int id;
  final Reward reward;
  final String status;
  final String? remarks;
  final DateTime redeemedAt;

  RewardRedemption({
    required this.id,
    required this.reward,
    required this.status,
    this.remarks,
    required this.redeemedAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['id'] ?? 0,
      reward: json['reward'] is Map
          ? Reward.fromJson(json['reward'])
          : Reward(
              id: json['reward'] ?? 0,
              title: json['reward_title'] ?? 'Unknown Reward',
              description: '',
              rewardDetails: '',
              pointsRequired: 0,
              isActive: true,
              availableFrom: '',
              createdAt: '',
              updatedAt: '',
            ),
      status: json['status'] ?? 'completed', // default for completed redemptions
      remarks: json['remarks'] ?? '',
      redeemedAt: DateTime.tryParse(json['redeemed_at'] ?? '') ??
          DateTime.now(), // fallback to now if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reward': reward.toJson(),
      'status': status,
      'remarks': remarks,
      'redeemed_at': redeemedAt.toIso8601String(),
    };
  }

  /// Optional: nice readable string for debugging or logs
  @override
  String toString() {
    final formattedDate =
        "${redeemedAt.year}-${redeemedAt.month.toString().padLeft(2, '0')}-${redeemedAt.day.toString().padLeft(2, '0')}";
    return "RewardRedemption(id: $id, reward: ${reward.title}, status: $status, date: $formattedDate)";
  }
}
