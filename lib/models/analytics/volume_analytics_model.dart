class VolumeAnalytics {
  final double totalVolume;
  final Map<String, double> byType;
  final Map<String, double> byMonth;

  VolumeAnalytics({
    required this.totalVolume,
    required this.byType,
    required this.byMonth,
  });

  factory VolumeAnalytics.fromJson(Map<String, dynamic> json) {
    return VolumeAnalytics(
      totalVolume: (json['total_volume'] ?? 0).toDouble(),
      byType: (json['by_type'] ?? {})
          .map<String, double>((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      byMonth: (json['by_month'] ?? {})
          .map<String, double>((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }
}
