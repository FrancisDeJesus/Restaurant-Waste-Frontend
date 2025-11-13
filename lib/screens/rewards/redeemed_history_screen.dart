import 'package:flutter/material.dart';
import '../../models/rewards/redeemed_history_model.dart';
import '../../services/api/rewards_api.dart';

class RedeemedHistoryScreen extends StatefulWidget {
  const RedeemedHistoryScreen({super.key});

  @override
  State<RedeemedHistoryScreen> createState() => _RedeemedHistoryScreenState();
}

class _RedeemedHistoryScreenState extends State<RedeemedHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<RedeemedHistory> _history = [];

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
      final data = await RewardsApi.getRedeemedHistory();
      setState(() {
        _history = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redemption History"),
        backgroundColor: const Color(0xFF015704),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())

          : _error != null
              ? Center(child: Text("Error: $_error"))

              : _history.isEmpty
                  ? _buildEmptyState()

                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final item = _history[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(Icons.card_giftcard,
                                color: Color(0xFF015704), size: 32),
                            title: Text(item.rewardName),
                            subtitle: Text(
                                "Points Used: ${item.pointsUsed}\nDate: ${item.dateRedeemed}"),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "No redemption history yet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 10),
            Text(
              "Your redeemed rewards will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
