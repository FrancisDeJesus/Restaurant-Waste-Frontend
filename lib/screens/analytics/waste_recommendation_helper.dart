import 'package:flutter/material.dart';

/// A single waste reduction recommendation with a category icon and message.
class WasteRecommendation {
  final IconData icon;
  final String title;
  final String message;

  const WasteRecommendation({
    required this.icon,
    required this.title,
    required this.message,
  });
}

class WasteRecommendationHelper {
  static List<WasteRecommendation> buildRecommendations(
    Map<String, double> byType,
  ) {
    final percentages = _calculatePercentages(byType);
    final results = <WasteRecommendation>[];

    final kitchenPct = percentages['kitchen'] ?? 0;
    final customerPct = percentages['customer'] ?? 0;
    final foodPct = percentages['food'] ?? 0;

    if (kitchenPct > 50) {
      results.add(WasteRecommendation(
        icon: Icons.outdoor_grill_outlined,
        title: 'Kitchen Waste (${kitchenPct.toStringAsFixed(1)}%)',
        message:
            'Kitchen waste is your largest contributor at ${kitchenPct.toStringAsFixed(1)}%. '
            'Improve preparation planning, reduce over-peeling of ingredients, '
            'and tighten stock rotation to cut spoilage.',
      ));
    }

    if (customerPct > 20) {
      results.add(WasteRecommendation(
        icon: Icons.people_outline_rounded,
        title: 'Customer Waste (${customerPct.toStringAsFixed(1)}%)',
        message:
            'Customer plate waste accounts for ${customerPct.toStringAsFixed(1)}% of total waste. '
            'Consider offering half-portion options, smaller default servings, '
            'and convenient take-home packaging.',
      ));
    }

    if (foodPct > 10) {
      results.add(WasteRecommendation(
        icon: Icons.restaurant_outlined,
        title: 'Food Waste (${foodPct.toStringAsFixed(1)}%)',
        message:
            'Food waste is at ${foodPct.toStringAsFixed(1)}%. '
            'Consider enrolling in a food donation drive, improving daily inventory '
            'forecasting, and monitoring unsold dish quantities each service.',
      ));
    }

    if (results.isEmpty) {
      results.add(WasteRecommendation(
        icon: Icons.check_circle_outline_rounded,
        title: 'Looking Good!',
        message:
            'Waste levels are within healthy ranges. '
            'Maintain current segregation practices and keep monitoring '
            'to sustain this performance.',
      ));
    }

    return results;
  }

  static Map<String, double> _calculatePercentages(Map<String, double> byType) {
    final normalized = <String, double>{
      'kitchen': 0,
      'customer': 0,
      'food': 0,
    };

    for (final entry in byType.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value.isFinite ? entry.value : 0.0;
      final safeValue = value < 0 ? 0.0 : value;

      if (key.contains('kitchen')) {
        normalized['kitchen'] = (normalized['kitchen'] ?? 0) + safeValue;
      }
      if (key.contains('customer')) {
        normalized['customer'] = (normalized['customer'] ?? 0) + safeValue;
      }
      if (key.contains('food')) {
        normalized['food'] = (normalized['food'] ?? 0) + safeValue;
      }
    }

    final total = normalized.values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) {
      return {
        'kitchen': 0,
        'customer': 0,
        'food': 0,
      };
    }

    return {
      'kitchen': ((normalized['kitchen'] ?? 0) / total) * 100,
      'customer': ((normalized['customer'] ?? 0) / total) * 100,
      'food': ((normalized['food'] ?? 0) / total) * 100,
    };
  }
}
