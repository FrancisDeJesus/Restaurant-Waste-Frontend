// lib/screens/drivers/driver_assigned_pickups_screen.dart
import 'package:flutter/material.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';
import '../../services/api/driver_api.dart';
import '../../services/api_service.dart';
import 'driver_map_screen.dart';
import 'driver_dashboard_screen.dart'; // for safe back navigation

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
  final Color green = const Color(0xFF015704);

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
      final pickups = await DriverApi.getAssignedPickups(widget.driverId);
      setState(() => _pickups = pickups);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptPickup(
      int pickupId, double lat, double lng, String address) async {
    try {
      await DriverApi.acceptPickup(widget.driverId, pickupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pickup accepted! Opening map...')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DriverMapScreen(pickupLat: lat, pickupLng: lng, address: address),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to accept pickup: $e')),
      );
    }
  }

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

  Future<void> _completePickup(int pickupId) async {
    try {
      final response =
          await ApiService.patch("trash_pickups/$pickupId/complete/", {});
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('✅ Pickup completed successfully! Points awarded.')),
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

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey.shade800),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DriverDashboardScreen(driverId: widget.driverId)),
              );
            }
          },
        ),
        title: const Text(
          "Assigned Pickups",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPickups,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _pickups.isEmpty
                    ? const Center(
                        child: Text(
                          "No assigned pickups yet",
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        itemCount: _pickups.length,
                        itemBuilder: (context, i) {
                          final p = _pickups[i];
                          return _buildPickupCard(p);
                        },
                      ),
      ),
    );
  }

  // ==================== CARD DESIGN ====================
  Widget _buildPickupCard(TrashPickup p) {
    final statusColor = _getStatusColor(p.status);
    final buttonText = _getActionLabel(p.status);
    final buttonAction = _getActionCallback(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: "View on Map",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverMapScreen(
                        pickupLat: p.latitude ?? 0.0,
                        pickupLng: p.longitude ?? 0.0,
                        address: p.address,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_rounded, color: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            "${p.wasteType} Waste",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),

          _buildInfoRow(Icons.scale, "${p.weightKg.toStringAsFixed(1)} kg"),
          _buildInfoRow(Icons.location_on, p.address, multiline: true),

          const SizedBox(height: 12),

          // Action button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: buttonAction,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              label: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: multiline ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orangeAccent;
      case "accepted":
        return Colors.blueAccent;
      case "in_progress":
        return green;
      case "completed":
        return Colors.grey;
      default:
        return Colors.black45;
    }
  }

  String _getActionLabel(String status) {
    switch (status) {
      case "pending":
        return "Accept";
      case "accepted":
        return "Start";
      case "in_progress":
        return "Complete";
      case "completed":
        return "Done";
      default:
        return "Action";
    }
  }

  VoidCallback? _getActionCallback(TrashPickup p) {
    switch (p.status) {
      case "pending":
        return () => _acceptPickup(
              p.id!,
              p.latitude ?? 0.0,
              p.longitude ?? 0.0,
              p.address,
            );
      case "accepted":
        return () => _startPickup(p.id!);
      case "in_progress":
        return () => _completePickup(p.id!);
      default:
        return null;
    }
  }
}
