import 'reward_model.dart';

class RewardRedemption {
  final int? id;
  final Reward reward;
  final String status;
  final DateTime redeemedAt;

  RewardRedemption({
    this.id,
    required this.reward,
    required this.status,
    required this.redeemedAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['id'],
      reward: Reward.fromJson(json['reward']),
      status: json['status'] ?? 'pending',
      redeemedAt: DateTime.parse(json['redeemed_at']),
    );
  }
}
