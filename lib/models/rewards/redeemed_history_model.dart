class RedeemedHistory {
  final int id;
  final String rewardName;
  final int pointsUsed;
  final String dateRedeemed;

  RedeemedHistory({
    required this.id,
    required this.rewardName,
    required this.pointsUsed,
    required this.dateRedeemed,
  });

  factory RedeemedHistory.fromJson(Map<String, dynamic> json) {
    return RedeemedHistory(
      id: json['id'],
      rewardName: json['reward_name'],
      pointsUsed: json['points_used'],
      dateRedeemed: json['date_redeemed'],
    );
  }
}
