// lib/models/subscriptions/subscription_model.dart

class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final String planType;
  final double price;
  final int durationDays;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.planType,
    required this.price,
    required this.durationDays,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      planType: json['plan_type'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      durationDays: json['duration_days'] ?? 0,
    );
  }
}

// =======================================================
// 🧾 SUBSCRIPTION MODEL (for active + history)
// =======================================================
class Subscription {
  final int id;
  final String planName;
  final String paymentMethod;
  final String startDate;
  final String endDate;
  final bool isActive;

  Subscription({
    required this.id,
    required this.planName,
    required this.paymentMethod,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    return Subscription(
      id: json['id'] ?? 0,
      planName: plan != null
          ? (plan['name'] ?? 'Unknown Plan')
          : (json['plan_name'] ?? 'Unknown Plan'),
      paymentMethod: json['payment_method'] ?? 'N/A',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}
