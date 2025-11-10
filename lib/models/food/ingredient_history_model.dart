class IngredientHistory {
  final String changeType;
  final double amount;
  final String unit;
  final String timestamp;
  final String? note;

  IngredientHistory({
    required this.changeType,
    required this.amount,
    required this.unit,
    required this.timestamp,
    this.note,
  });

  factory IngredientHistory.fromJson(Map<String, dynamic> json) => IngredientHistory(
        changeType: json['change_type'],
        amount: (json['amount'] as num).toDouble(),
        unit: json['unit'],
        timestamp: json['timestamp'],
        note: json['note'],
      );
}
