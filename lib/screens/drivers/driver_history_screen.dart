// lib/screens/drivers/driver_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trash_pickup/trash_pickup_model.dart';
import '../../services/api/driver_api.dart';
import 'driver_dashboard_screen.dart'; // ✅ for safe fallback navigation

class DriverHistoryScreen extends StatefulWidget {
  final int driverId;

  const DriverHistoryScreen({super.key, required this.driverId});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<TrashPickup> _history = [];
  final Color green = const Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey.shade800),
          onPressed: () {
            // ✅ Option 2: Safe back navigation
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DriverDashboardScreen(driverId: widget.driverId),
                ),
              );
            }
          },
        ),
        title: const Text(
          "Pickup History",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _history.isEmpty
                      ? const Center(
                          child: Text(
                            "No completed pickups yet",
                            style: TextStyle(
                                fontSize: 15, color: Colors.black54),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          children: [
                            // HEADER SUMMARY (minimal)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10, top: 4),
                              child: Row(
                                children: [
                                  const Text(
                                    "Total Completed Pickups",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${_history.length}",
                                    style: TextStyle(
                                      color: green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // HISTORY LIST
                            ..._history
                                .map((pickup) => _buildHistoryCard(pickup))
                                .toList(),
                          ],
                        ),
            ),
    );
  }

  // ===================================================
  // 🧾 MINIMAL CARD DESIGN
  // ===================================================
  Widget _buildHistoryCard(TrashPickup h) {
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
          // Header Row (status + icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: green, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    "Completed",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(h.updatedAt ?? h.createdAt),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Waste Type
          Text(
            "${h.wasteType} Waste",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),

          // Details
          _buildInfoRow(Icons.scale, "${h.weightKg.toStringAsFixed(1)} kg"),
          _buildInfoRow(Icons.location_on, h.address, multiline: true),
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
              maxLines: multiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
