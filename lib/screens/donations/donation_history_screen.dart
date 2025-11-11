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
        return Colors.orangeAccent;
      case 'kitchen':
        return const Color(0xFF015704);
      case 'customer':
        return Colors.blueAccent;
      default:
        return Colors.grey;
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
          'DONATION HISTORY',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: RefreshIndicator(
        color: green,
        onRefresh: _loadHistory,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: green))
            : _history.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 150),
                      Center(
                        child: Text(
                          'No donation history found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 🌱 TOTAL DONATION CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: green.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: green,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Trash Donated',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_totalDonated.toStringAsFixed(2)} kg',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🧾 DONATION LIST
                      ..._history.map((donation) {
                        final color = _wasteColor(donation.wasteType);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.recycling,
                                    color: color, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      donation.driveTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Waste Type: ${donation.wasteType}\n'
                                      'Weight: ${donation.weightKg.toStringAsFixed(2)} kg',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${DateFormat('MMM d, yyyy • h:mm a').format(donation.donatedAt)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
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
