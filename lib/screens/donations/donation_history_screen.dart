import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/donations/donation_model.dart';
import '../../services/api/donations_api.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  bool _loading = true;
  List<Donation> _history = [];
  double _totalDonated = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
    });

    try {
      final history = await DonationsApi.getHistory();
      final total = await DonationsApi.getTotalDonated();

      setState(() {
        _history = history;
        _totalDonated = total;
      });
    } catch (e) {
      // Instead of showing error, just clear data and show "No history"
      setState(() {
        _history = [];
        _totalDonated = 0.0;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _wasteColor(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'kitchen':
        return Colors.green;
      case 'customer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation History')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No donation history found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🌱 Total Trash Donated',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_totalDonated.toStringAsFixed(2)} kg',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._history.map((donation) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _wasteColor(donation.wasteType),
                              child: const Icon(Icons.recycling,
                                  color: Colors.white),
                            ),
                            title: Text(
                              donation.driveTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Waste: ${donation.wasteType}\n'
                              'Weight: ${donation.weightKg.toStringAsFixed(2)} kg\n'
                              'Date: ${DateFormat('MMM d, yyyy • h:mm a').format(donation.donatedAt)}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
      ),
    );
  }
}
