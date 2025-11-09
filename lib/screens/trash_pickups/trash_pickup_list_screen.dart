import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/trash_pickups/trash_pickup_model.dart';
import '../../../services/api/trash_pickups_api.dart';
import 'trash_pickup_form_screen.dart';
import 'trash_pickup_detail_screen.dart';
import 'trash_pickup_history_screen.dart';

class TrashPickupListScreen extends StatefulWidget {
  const TrashPickupListScreen({super.key});

  @override
  State<TrashPickupListScreen> createState() => _TrashPickupListScreenState();
}

class _TrashPickupListScreenState extends State<TrashPickupListScreen> {
  bool _loading = true;
  String? _error;
  List<TrashPickup> _pickups = [];

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  Future<void> _loadPickups() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await TrashPickupsApi.getAll();
      data.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _pickups = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelPickup(TrashPickup p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Pickup'),
        content: const Text('Are you sure you want to cancel this pickup request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await TrashPickupsApi.cancel(p.id!); // make sure this API endpoint exists
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pickup cancelled successfully!')),
      );
      await _loadPickups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Pickups'),
        actions: [
          IconButton(
            tooltip: 'View History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashPickupHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPickups,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    )
                  ])
                : _pickups.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No pickups yet. Tap + to request one.')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _pickups.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) {
                          final p = _pickups[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(p.status),
                              child: const Icon(Icons.recycling, color: Colors.white),
                            ),
                            title: Text(p.wasteTypeDisplay),
                            subtitle: Text(
                              "Weight: ${p.weightKg} kg\n"
                              "Status: ${p.status.toUpperCase()}\n"
                              "Schedule: ${DateFormat('MMM d, yyyy • h:mm a').format(p.scheduleDate)}",
                            ),
                            isThreeLine: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrashPickupDetailScreen(pickup: p),
                              ),
                            ),
                            trailing: (p.status == 'pending' || p.status == 'accepted')
                                ? IconButton(
                                    tooltip: 'Cancel Pickup',
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () => _cancelPickup(p),
                                  )
                                : null,
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrashPickupFormScreen()),
        ).then((changed) {
          if (changed == true) _loadPickups();
        }),
        child: const Icon(Icons.add),
      ),
    );
  }
}
