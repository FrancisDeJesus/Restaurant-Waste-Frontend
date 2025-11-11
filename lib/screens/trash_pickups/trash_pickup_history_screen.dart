import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/trash_pickups/trash_pickup_model.dart';
import '../../../services/api/trash_pickups_api.dart';
import 'trash_pickup_detail_screen.dart';

class TrashPickupHistoryScreen extends StatefulWidget {
  const TrashPickupHistoryScreen({super.key});

  @override
  State<TrashPickupHistoryScreen> createState() =>
      _TrashPickupHistoryScreenState();
}

class _TrashPickupHistoryScreenState extends State<TrashPickupHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<TrashPickup> _completed = [];
  List<TrashPickup> _cancelled = [];

  static const Color green = Color(0xFF015704);

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
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // =====================================================
  // 🧾 SECTION BUILDER
  // =====================================================
  Widget _buildSection(String title, List<TrashPickup> pickups) {
    if (pickups.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...pickups.map((p) => Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _statusColor(p.status).withOpacity(0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: _statusColor(p.status),
                  child: const Icon(Icons.recycling, color: Colors.white),
                ),
                title: Text(
                  p.wasteTypeDisplay.isNotEmpty
                      ? p.wasteTypeDisplay
                      : "Trash Pickup",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Weight: ${p.weightKg} kg\n"
                    "Status: ${p.status.toUpperCase()}\n"
                    "Updated: ${DateFormat('MMM d, yyyy • h:mm a').format(p.updatedAt)}",
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.4,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(p.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(p.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
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

  // =====================================================
  // 🧩 MAIN BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Past Transactions",
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: green),
              )
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
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                        ),
                      _buildSection(" Completed Pickups", _completed),
                      _buildSection(" Cancelled Pickups", _cancelled),
                      const SizedBox(height: 40),
                    ],
                  ),
      ),
    );
  }
}
