import 'package:flutter/material.dart';
import '../../models/rewards/reward_model.dart';
import '../../services/api/rewards_api.dart';
import 'redeemed_history_screen.dart';

class RewardsListScreen extends StatefulWidget {
  const RewardsListScreen({super.key});

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

  Future<void> _redeemReward(Reward reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Redeem "${reward.title}"?'),
        content: Text(
          'This will use ${reward.pointsRequired} points. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await RewardsApi.redeemReward(reward.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Reward redeemed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rewards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Redemption History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemedHistoryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRewards,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  ])
                : _rewards.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No rewards available.')),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _rewards.length,
                        itemBuilder: (context, i) {
                          final r = _rewards[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade700,
                                child: const Icon(Icons.card_giftcard, color: Colors.white),
                              ),
                              title: Text(
                                r.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${r.description}\nPoints Required: ${r.pointsRequired}',
                              ),
                              isThreeLine: true,
                              trailing: FilledButton(
                                onPressed: () => _redeemReward(r),
                                child: const Text('Redeem'),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
