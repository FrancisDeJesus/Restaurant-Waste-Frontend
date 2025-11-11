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
      await TrashPickupsApi.cancel(p.id!);
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
    const green = Color(0xFF015704);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TRASH PICK UP',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'View History',
            icon: const Icon(Icons.history, color: green),
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
            ? const Center(child: CircularProgressIndicator(color: green))
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
                          Center(
                            child: Text(
                              'No pickups yet.\nTap the green button below to request one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pickups.length,
                        itemBuilder: (context, i) {
                          final p = _pickups[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: _statusColor(p.status).withOpacity(0.2),
                                width: 1.2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: _statusColor(p.status),
                                child: const Icon(Icons.local_shipping_rounded,
                                    color: Colors.white),
                              ),
                              title: Text(
                                "Trash Pick Up",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Weight: ${p.weightKg} kg\n"
                                  "Status: ${p.status.toUpperCase()}\n"
                                  "Schedule: ${DateFormat('MMM d, yyyy • h:mm a').format(p.scheduleDate)}",
                                  style: const TextStyle(height: 1.4),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (p.status == 'completed')
                                    const Text("+ 20 PTS",
                                        style: TextStyle(
                                            color: green,
                                            fontWeight: FontWeight.bold)),
                                  if (p.status == 'cancelled')
                                    const Text("CANCELLED",
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold)),
                                  if (p.status == 'pending' ||
                                      p.status == 'accepted')
                                    IconButton(
                                      tooltip: 'Cancel Pickup',
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.redAccent),
                                      onPressed: () => _cancelPickup(p),
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TrashPickupDetailScreen(pickup: p),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrashPickupFormScreen()),
        ).then((changed) {
          if (changed == true) _loadPickups();
        }),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
