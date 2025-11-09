import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/trash_pickups/trash_pickup_model.dart';
import '../../../services/api/trash_pickups_api.dart';
import 'trash_pickup_detail_screen.dart';

class TrashPickupHistoryScreen extends StatefulWidget {
  const TrashPickupHistoryScreen({super.key});

  @override
  State<TrashPickupHistoryScreen> createState() => _TrashPickupHistoryScreenState();
}

class _TrashPickupHistoryScreenState extends State<TrashPickupHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<TrashPickup> _completed = [];
  List<TrashPickup> _cancelled = [];

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
      final all = await TrashPickupsApi.getAll();
      final completed = all.where((p) => p.status == 'completed').toList();
      final cancelled = all.where((p) => p.status == 'cancelled').toList();

      completed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      cancelled.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      setState(() {
        _completed = completed;
        _cancelled = cancelled;
      });
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
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSection(String title, List<TrashPickup> pickups) {
    if (pickups.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...pickups.map((p) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(p.status),
                  child: const Icon(Icons.recycling, color: Colors.white),
                ),
                title: Text(
                  p.wasteTypeDisplay,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Weight: ${p.weightKg} kg\n"
                  "Status: ${p.status.toUpperCase()}\n"
                  "Updated: ${DateFormat('MMM d, yyyy • h:mm a').format(p.updatedAt)}",
                ),
                isThreeLine: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrashPickupDetailScreen(pickup: p),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup History')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ])
                : ListView(
                    children: [
                      if (_completed.isEmpty && _cancelled.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(
                            child: Text(
                              'No past pickups found.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      _buildSection("✅ Completed Pickups", _completed),
                      _buildSection("❌ Cancelled Pickups", _cancelled),
                      const SizedBox(height: 30),
                    ],
                  ),
      ),
    );
  }
}
