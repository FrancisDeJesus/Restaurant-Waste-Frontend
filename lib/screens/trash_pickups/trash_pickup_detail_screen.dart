import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/trash_pickups/trash_pickup_model.dart';
import '../../../services/api/trash_pickups_api.dart';

class TrashPickupDetailScreen extends StatefulWidget {
  final TrashPickup pickup;
  const TrashPickupDetailScreen({super.key, required this.pickup});

  @override
  State<TrashPickupDetailScreen> createState() => _TrashPickupDetailScreenState();
}

class _TrashPickupDetailScreenState extends State<TrashPickupDetailScreen> {
  bool _cancelling = false;

  Future<void> _cancelPickup() async {
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

    setState(() => _cancelling = true);
    try {
      await TrashPickupsApi.cancel(widget.pickup.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' Pickup cancelled successfully!')),
      );
      Navigator.pop(context, true); // return to list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);
    final pickup = widget.pickup;
    final statusColor = {
      'pending': Colors.orange,
      'accepted': Colors.blue,
      'in_progress': Colors.amber,
      'completed': Colors.green,
      'cancelled': Colors.red,
    }[pickup.status] ?? Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PICKUP DETAILS',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickup.wasteTypeDisplay.isNotEmpty
                          ? pickup.wasteTypeDisplay
                          : "Trash Pickup",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.circle, color: statusColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    pickup.status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1.1),

              // DETAILS
              _detailRow(" Address", pickup.address),
              _detailRow(" Weight (kg)", "${pickup.weightKg.toStringAsFixed(1)}"),
              _detailRow(
                "🗓 Scheduled Pickup",
                DateFormat('MMMM d, yyyy • h:mm a').format(pickup.scheduleDate),
              ),
              _detailRow(
                " Created",
                DateFormat('MMM d, yyyy • h:mm a').format(pickup.createdAt),
              ),
              _detailRow(
                " Last Updated",
                DateFormat('MMM d, yyyy • h:mm a').format(pickup.updatedAt),
              ),

              const Spacer(),

              // STATUS TAG
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    pickup.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CANCEL BUTTON (only for pending)
              if (pickup.status == 'pending')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.white),
                    label: Text(
                      _cancelling ? 'Cancelling...' : 'Cancel Pickup',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    onPressed: _cancelling ? null : _cancelPickup,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
