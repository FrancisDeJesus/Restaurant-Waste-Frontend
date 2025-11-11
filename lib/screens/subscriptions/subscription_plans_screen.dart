import 'package:flutter/material.dart';
import '../../services/api/subscriptions_api.dart';
import '../../models/subscriptions/subscription_model.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _loading = true;
  String? _error;
  List<SubscriptionPlan> _plans = [];
  static const Color green = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final data = await SubscriptionsApi.getPlans();
      setState(() {
        _plans = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _subscribe(int id) async {
    final success = await SubscriptionsApi.subscribeToPlan(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Subscribed successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Subscription failed.")),
      );
    }
  }

  // 🧩 Local fallback (if backend doesn’t return icons)
  String _getPlanImage(String name) {
    switch (name.toLowerCase()) {
      case "basic":
        return "assets/basic.png";
      case "eco":
        return "assets/eco_sub.png";
      case "premium":
        return "assets/premium.png";
      default:
        return "assets/basic.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_error != null) {
      return Center(child: Text("Error: $_error"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟩 Title (left-aligned)
              Text(
                "${plan.name.toUpperCase()} SUBSCRIPTION",
                style: const TextStyle(
                  color: green,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 22, thickness: 0.8),

              // 🖼️ + 📋 Content Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼️ Image
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Image.asset(
                      _getPlanImage(plan.name),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 📋 Plan Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.description,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "₱${plan.price.toStringAsFixed(2)} / ${plan.durationDays} Days",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 🟢 Subscribe Button (left-aligned)
                        SizedBox(
                          width: 120,
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () => _subscribe(plan.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "SUBSCRIBE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
