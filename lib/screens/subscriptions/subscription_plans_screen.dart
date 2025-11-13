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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final padding = isSmall ? 12.0 : 16.0;
    final titleFont = isSmall ? 15.5 : 17.0;
    final textFont = isSmall ? 13.0 : 14.5;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }
    if (_error != null) {
      return Center(
        child: Text(
          "Error: $_error",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontSize: 15),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        title: const Text(
          'SUBSCRIPTION PLANS',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlans,
        child: ListView.builder(
          padding: EdgeInsets.all(padding),
          itemCount: _plans.length,
          itemBuilder: (context, index) {
            final plan = _plans[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: EdgeInsets.all(padding),
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
                  // 🟩 Title
                  Text(
                    "${plan.name.toUpperCase()} SUBSCRIPTION",
                    style: TextStyle(
                      color: green,
                      fontSize: titleFont,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(height: 20, thickness: 0.8, color: Colors.grey.shade300),

                  // 🖼️ + 📋 Plan Details Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼️ Image
                      Container(
                        width: isSmall ? 70 : 90,
                        height: isSmall ? 70 : 90,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          _getPlanImage(plan.name),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 📋 Plan Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.description,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: textFont,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₱${plan.price.toStringAsFixed(2)} / ${plan.durationDays} Days",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: textFont,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 🟢 Subscribe Button
                            SizedBox(
                              width: isSmall ? 110 : 130,
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
                                child: Text(
                                  "SUBSCRIBE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    fontSize: textFont,
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
        ),
      ),
    );
  }
}
