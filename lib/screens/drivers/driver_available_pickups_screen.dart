// lib/screens/drivers/driver_available_pickups_screen.dart
import 'package:flutter/material.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';
import '../../services/api/driver_api.dart';

class DriverAvailablePickupsScreen extends StatefulWidget {
  final int driverId; // 👈 required for accepting pickups

  const DriverAvailablePickupsScreen({super.key, required this.driverId});

  @override
  State<DriverAvailablePickupsScreen> createState() =>
      _DriverAvailablePickupsScreenState();
}

class _DriverAvailablePickupsScreenState
    extends State<DriverAvailablePickupsScreen> {
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
      final pickups = await DriverApi.getAvailablePickups();
      setState(() => _pickups = pickups);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptPickup(int pickupId) async {
    try {
      await DriverApi.acceptPickup(widget.driverId, pickupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Pickup accepted successfully")),
      );
      _loadPickups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to accept pickup: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPickups,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pickups.isEmpty
                  ? const Center(child: Text("No available pickups"))
                  : ListView.builder(
                      itemCount: _pickups.length,
                      itemBuilder: (context, i) {
                        final p = _pickups[i];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              "${p.wasteType} Waste",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                "Weight: ${p.weightKg} kg\nAddress: ${p.address}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _acceptPickup(p.id!),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Accept"),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
