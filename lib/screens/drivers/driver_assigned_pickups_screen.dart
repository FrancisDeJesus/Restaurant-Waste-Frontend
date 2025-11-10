// lib/screens/drivers/driver_assigned_pickups_screen.dart
import 'package:flutter/material.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';
import '../../services/api/driver_api.dart';
import 'driver_map_screen.dart'; // ✅ make sure this file exists
import '../../services/api_service.dart';


class DriverAssignedPickupsScreen extends StatefulWidget {
  final int driverId;

  const DriverAssignedPickupsScreen({super.key, required this.driverId});

  @override
  State<DriverAssignedPickupsScreen> createState() =>
      _DriverAssignedPickupsScreenState();
}

class _DriverAssignedPickupsScreenState
    extends State<DriverAssignedPickupsScreen> {
  bool _loading = true;
  String? _error;
  List<TrashPickup> _pickups = [];

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  // =====================================================
  // 🔄 Load assigned pickups
  // =====================================================
  Future<void> _loadPickups() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pickups = await DriverApi.getAssignedPickups(widget.driverId);
      setState(() => _pickups = pickups);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // =====================================================
  // ✅ Accept pickup + open map
  // =====================================================
  Future<void> _acceptPickup(
      int pickupId, double lat, double lng, String address) async {
    try {
      await DriverApi.acceptPickup(widget.driverId, pickupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pickup accepted! Opening map...')),
      );

      // 🚗 Navigate to map screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverMapScreen(
            pickupLat: lat,
            pickupLng: lng,
            address: address,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to accept pickup: $e')),
      );
    }
  }

  // =====================================================
  // 🚚 Start pickup
  // =====================================================
  Future<void> _startPickup(int pickupId) async {
    try {
      await DriverApi.startPickup(widget.driverId, pickupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚚 Pickup started')),
      );

      final pickup = _pickups.firstWhere((p) => p.id == pickupId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverMapScreen(
            pickupLat: pickup.latitude ?? 0.0,
            pickupLng: pickup.longitude ?? 0.0,
            address: pickup.address,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to start pickup: $e')),
      );
    }
  }

  // =====================================================
  // 🏁 Complete pickup
  // =====================================================
  Future<void> _completePickup(int pickupId) async {
    try {
      // ✅ Call the correct endpoint directly
      final response =
          await ApiService.patch("trash_pickups/$pickupId/complete/", {});
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pickup completed successfully! Points awarded.')),
        );
        _loadPickups();
      } else {
        final body = response.body.isNotEmpty ? response.body : "Unknown error";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to complete pickup: $body')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to complete pickup: $e')),
      );
    }
  }

  // =====================================================
  // 🧱 UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPickups,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pickups.isEmpty
                  ? const Center(child: Text("No assigned pickups"))
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
                                "Weight: ${p.weightKg} kg\nStatus: ${p.status}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              onPressed: p.status == "pending"
                                  ? () => _acceptPickup(
                                      p.id!,
                                      p.latitude ?? 0.0,
                                      p.longitude ?? 0.0,
                                      p.address,
                                    )
                                  : p.status == "accepted"
                                      ? () => _startPickup(p.id!)
                                      : p.status == "in_progress"
                                          ? () => _completePickup(p.id!)
                                          : null,
                              child: Text(
                                p.status == "pending"
                                    ? "Accept"
                                    : p.status == "accepted"
                                        ? "Start"
                                        : p.status == "in_progress"
                                            ? "Complete"
                                            : "Done",
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
