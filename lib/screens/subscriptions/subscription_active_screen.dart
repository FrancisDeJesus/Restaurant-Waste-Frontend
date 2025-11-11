import 'package:flutter/material.dart';
import '../../services/api/subscriptions_api.dart';
import '../../models/subscriptions/subscription_model.dart';

class SubscriptionActiveScreen extends StatefulWidget {
  const SubscriptionActiveScreen({super.key});

  @override
  State<SubscriptionActiveScreen> createState() =>
      _SubscriptionActiveScreenState();
}

class _SubscriptionActiveScreenState extends State<SubscriptionActiveScreen> {
  Subscription? _active;
  bool _loading = true;
  static const Color green = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    try {
      final data = await SubscriptionsApi.getActiveSubscription();
      setState(() {
        _active = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: green))
              : _active == null
                  ? const Center(
                      child: Text(
                        "No active subscription plan.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : _buildActiveCard(),
        ),
      ),
    );
  }

  // ============================================================
  // 🧾 ACTIVE PLAN CARD (LEFT-ALIGNED)
  // ============================================================
  Widget _buildActiveCard() {
    return Align(
      alignment: Alignment.topLeft, // ✅ Aligns the card to the left
      child: Container(
        width: 500, // ✅ Fixed width for clean alignment
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(left: 4, top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start, // ✅ Text & layout left-aligned
          children: [
            // 💡 Plan name
            Text(
              _active!.planName.toUpperCase(),
              style: const TextStyle(
                color: green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 20, thickness: 0.8),

            // 🧩 Plan info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/eco_sub.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: "Valid Until:", value: _active!.endDate),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: "Payment Method:",
                        value: _active!.paymentMethod,
                        valueColor: Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: "Status:",
                        value: _active!.isActive ? "Active" : "Inactive",
                        valueColor: _active!.isActive
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🧩 INFO ROW WIDGET
// ============================================================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
