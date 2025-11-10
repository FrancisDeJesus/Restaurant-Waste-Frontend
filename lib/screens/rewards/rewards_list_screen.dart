import 'package:flutter/material.dart';
import '../../models/rewards/reward_model.dart';
import '../../services/api/rewards_api.dart';

class RewardsListScreen extends StatefulWidget {
  final int userPoints; // ✅ Pass the logged-in user's points

  const RewardsListScreen({super.key, required this.userPoints});

  @override
  State<RewardsListScreen> createState() => _RewardsListScreenState();
}

class _RewardsListScreenState extends State<RewardsListScreen> {
  bool _loading = true;
  String? _error;
  List<Reward> _rewards = [];

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rewards = await RewardsApi.getAll();
      setState(() => _rewards = rewards);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // =====================================================
  // 🪙 Redeem reward API call
  // =====================================================
  Future<void> _redeemReward(int rewardId, String rewardTitle, int pointsRequired) async {
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
        // Optionally refresh or deduct points locally
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Redemption failed. Please try again.")),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rewards')),
      body: RefreshIndicator(
        onRefresh: _loadRewards,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : _rewards.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text('No rewards available at the moment.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _rewards.length,
                        itemBuilder: (context, i) {
                          final r = _rewards[i];
                          final canRedeem = widget.userPoints >= r.pointsRequired;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.teal,
                                        child: Icon(Icons.card_giftcard,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          r.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
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
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Points Required: ${r.pointsRequired}",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: canRedeem
                                              ? () => _redeemReward(
                                                  r.id, r.title, r.pointsRequired)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canRedeem
                                                ? Colors.green
                                                : Colors.grey,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                          ),
                                          child: Text(
                                            canRedeem ? "Redeem" : "Locked",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
