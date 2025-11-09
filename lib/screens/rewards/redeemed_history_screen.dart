import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rewards/reward_redemption_model.dart';
import '../../services/api/rewards_api.dart';

class RedeemedHistoryScreen extends StatefulWidget {
  const RedeemedHistoryScreen({super.key});

  @override
  State<RedeemedHistoryScreen> createState() => _RedeemedHistoryScreenState();
}

class _RedeemedHistoryScreenState extends State<RedeemedHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<RewardRedemption> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await RewardsApi.getHistory();
      setState(() => _history = history);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _history.where((h) => h.status == 'completed').toList();
    final pending = _history.where((h) => h.status == 'pending').toList();
    final declined = _history.where((h) => h.status == 'declined').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Redemption History')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : _history.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No redemption history found.')),
                        ],
                      )
                    : ListView(
                        children: [
                          if (completed.isNotEmpty) _buildSection('✅ Completed', completed),
                          if (pending.isNotEmpty) _buildSection('⏳ Pending', pending),
                          if (declined.isNotEmpty) _buildSection('❌ Declined', declined),
                        ],
                      ),
      ),
    );
  }

  Widget _buildSection(String title, List<RewardRedemption> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ...items.map((h) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(h.status),
                    child: const Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                  title: Text(h.reward.title),
                  subtitle: Text(
                    "Status: ${h.status.toUpperCase()}\n"
                    "Redeemed: ${DateFormat('MMM d, yyyy • h:mm a').format(h.redeemedAt)}",
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
