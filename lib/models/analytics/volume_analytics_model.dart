// lib/models/analytics/volume_analytics_model.dart
class VolumeAnalytics {
  final double totalVolume;
  final Map<String, double> byType;
  final Map<String, double> byMonth;
  final bool eligibleForRewards;

  VolumeAnalytics({
    required this.totalVolume,
    required this.byType,
    required this.byMonth,
    required this.eligibleForRewards,
  });

  factory VolumeAnalytics.fromJson(Map<String, dynamic> json) {
    final List<dynamic> byTypeList = json['waste_type_breakdown'] ?? [];
    final Map<String, double> byTypeMap = {};
    for (var item in byTypeList) {
      if (item is Map<String, dynamic>) {
        final type = item['waste_type']?.toString() ?? 'Unknown';
        final total = (item['total'] ?? 0).toDouble();
        byTypeMap[type] = total;
      }
    }

    final List<dynamic> byMonthList = json['waste_volume_trends'] ?? [];
    final Map<String, double> byMonthMap = {};
    for (var item in byMonthList) {
      if (item is Map<String, dynamic>) {
        final week = item['week']?.toString() ?? 'N/A';
        final weight = (item['total_weight'] ?? 0).toDouble();
        byMonthMap['Week $week'] = weight;
      }
    }

    return VolumeAnalytics(
      totalVolume: (json['total_monthly_waste'] ?? 0).toDouble(),
      byType: byTypeMap,
      byMonth: byMonthMap,
      eligibleForRewards: json['eligible_for_rewards'] ?? true,
    );
  }
}
