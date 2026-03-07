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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        const SnackBar(content: Text('Pickup cancelled successfully!')),
      );
      Navigator.pop(context, true);
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

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final padding = screenWidth < 400 ? 14.0 : 18.0;
    final titleFont = isSmall ? 18.0 : 20.0;
    final textFont = isSmall ? 13.5 : 15.0;

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
        elevation: 1,
        centerTitle: true,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'PICKUP DETAILS',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
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
              ),
            ],
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    width: isSmall ? 42 : 48,
                    height: isSmall ? 42 : 48,
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: green, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickup.wasteTypeDisplay.isNotEmpty
                          ? pickup.wasteTypeDisplay
                          : "Trash Pickup",
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      fontSize: textFont,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1.1),

              // DETAILS
              _detailRow("📍 Address", pickup.address, textFont),
              _detailRow(
                "⚖ Estimated Weight (kg)",
                "${(pickup.estimatedWeightKg ?? pickup.weightKg).toStringAsFixed(1)}",
                textFont,
              ),
              if ((pickup.actualWeightKg ?? 0) > 0)
                _detailRow(
                  "📏 Actual Weight (kg)",
                  "${pickup.actualWeightKg!.toStringAsFixed(1)}",
                  textFont,
                ),
              _detailRow(
                "🗓 Scheduled Pickup",
                DateFormat('MMMM d, yyyy • h:mm a').format(pickup.scheduleDate),
                textFont,
              ),
              _detailRow(
                "🕒 Created",
                DateFormat('MMM d, yyyy • h:mm a').format(pickup.createdAt),
                textFont,
              ),
              _detailRow(
                "🔄 Last Updated",
                DateFormat('MMM d, yyyy • h:mm a').format(pickup.updatedAt),
                textFont,
              ),
              if ((pickup.proofImageUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Photo Proof',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: textFont + 1,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    pickup.proofImageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      alignment: Alignment.center,
                      color: Colors.grey.shade100,
                      child: const Text('Unable to load proof photo.'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

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
                      fontSize: textFont,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        fontSize: textFont,
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

  Widget _detailRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize + 1,
                color: Colors.black87,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
