import 'package:flutter/material.dart';
import '../../models/rewards/reward_model.dart';
import '../../services/api/rewards_api.dart';
import '../../services/api/analytics_api.dart';
import '../../models/analytics/volume_analytics_model.dart';

class RewardsListScreen extends StatefulWidget {
  final int userPoints; // ✅ Logged-in user's current points

  const RewardsListScreen({super.key, required this.userPoints});

  @override
  State<RewardsListScreen> createState() => _RewardsListScreenState();
}

class _RewardsListScreenState extends State<RewardsListScreen> {
  bool _loading = true;
  String? _error;
  List<Reward> _rewards = [];
  bool _eligibleForRewards = true; // 🆕 Default eligible
  VolumeAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ Fetch both analytics and rewards
      final analytics = await AnalyticsApi.getVolumeAnalytics();
      final rewards = await RewardsApi.getAll();

      setState(() {
        _analytics = analytics;
        _eligibleForRewards = analytics.eligibleForRewards;
        _rewards = rewards;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // =====================================================
  // 🎁 Redeem reward API call
  // =====================================================
  Future<void> _redeemReward(int rewardId, String rewardTitle, int pointsRequired) async {
    if (!_eligibleForRewards) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ You’ve exceeded this month’s waste limit. Rewards will be available next month."),
        ),
      );
      return;
    }

    if (widget.userPoints < pointsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Not enough points to redeem this reward.")),
      );
      return;
    }

    try {
      final response = await RewardsApi.redeemReward(rewardId);
      if (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 You redeemed $rewardTitle successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Redemption failed. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'REWARDS',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: green))
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!_eligibleForRewards) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "⚠️ You’ve exceeded this month’s waste limit.\nReward redemption is locked until next month.",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_rewards.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Text(
                              'No rewards available at the moment.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._rewards.map((r) {
                          final canRedeem = widget.userPoints >= r.pointsRequired && _eligibleForRewards;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: canRedeem ? green.withOpacity(0.25) : Colors.grey.shade300,
                              ),
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: canRedeem ? green.withOpacity(0.15) : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.card_giftcard_rounded,
                                          color: canRedeem ? green : Colors.grey),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        r.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: canRedeem ? Colors.black87 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r.description,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                if (r.rewardDetails.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      "Details: ${r.rewardDetails}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Points Required: ${r.pointsRequired}",
                                      style: TextStyle(
                                        color: canRedeem ? green : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: canRedeem
                                            ? () => _redeemReward(r.id, r.title, r.pointsRequired)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: canRedeem ? green : Colors.grey.shade400,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 22),
                                        ),
                                        child: Text(
                                          _eligibleForRewards
                                              ? (canRedeem ? "Redeem" : "Locked")
                                              : "Locked",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
