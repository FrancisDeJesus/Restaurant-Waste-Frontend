// lib/screens/drivers/driver_available_pickups_screen.dart
import 'package:flutter/material.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';
import '../../services/api/driver_api.dart';
import 'driver_dashboard_screen.dart'; // ✅ for safe back navigation

class DriverAvailablePickupsScreen extends StatefulWidget {
  final int driverId;

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
  final Color green = const Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  Future<void> _loadPickups() async {
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

  // ===========================================================
  // 🧱 UI
  // ===========================================================
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
          "Available Pickups",
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
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)))
                : _pickups.isEmpty
                    ? const Center(
                        child: Text(
                          "No available pickups at the moment",
                          style: TextStyle(
                              fontSize: 15, color: Colors.black54),
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

  // ===========================================================
  // 🎨 CARD DESIGN
  // ===========================================================
  Widget _buildPickupCard(TrashPickup p) {
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
          ),
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
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "AVAILABLE",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.recycling_rounded, color: green, size: 22),
            ],
          ),
          const SizedBox(height: 10),

          // Waste Type
          Text(
            "${p.wasteType} Waste",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),

          // Details
          _buildInfoRow(Icons.scale, "${p.weightKg.toStringAsFixed(1)} kg"),
          _buildInfoRow(Icons.location_on, p.address, multiline: true),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => _acceptPickup(p.id!),
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
              label: const Text(
                "Accept Pickup",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
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
}
