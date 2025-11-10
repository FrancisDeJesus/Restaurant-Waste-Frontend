// lib/screens/drivers/driver_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';
import '../../services/api/driver_api.dart';

class DriverHistoryScreen extends StatefulWidget {
  final int driverId; // 👈 Required to load this driver's history

  const DriverHistoryScreen({super.key, required this.driverId});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<TrashPickup> _history = [];

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
      final history = await DriverApi.getHistory(widget.driverId);
      setState(() => _history = history);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown date";
    return DateFormat("MMM dd, yyyy – hh:mm a").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _history.isEmpty
                  ? const Center(child: Text("No completed pickups yet"))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final h = _history[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              "${h.wasteType} Waste",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                "Weight: ${h.weightKg} kg\nCompleted: ${_formatDate(h.updatedAt ?? h.createdAt)}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            leading: const Icon(Icons.check_circle,
                                color: Colors.green, size: 30),
                          ),
                        );
                      },
                    ),
    );
  }
}
