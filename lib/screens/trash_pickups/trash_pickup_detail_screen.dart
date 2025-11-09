import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/trash_pickups/trash_pickup_model.dart';

class TrashPickupDetailScreen extends StatelessWidget {
  final TrashPickup pickup;
  const TrashPickupDetailScreen({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      'pending': Colors.orange,
      'accepted': Colors.blue,
      'in_progress': Colors.amber,
      'completed': Colors.green,
      'cancelled': Colors.red,
    }[pickup.status] ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup.wasteTypeDisplay,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      pickup.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),

                Text("📍 Address:", style: _labelStyle),
                Text(pickup.address, style: _valueStyle),
                const SizedBox(height: 12),

                Text("⚖️ Weight (kg):", style: _labelStyle),
                Text("${pickup.weightKg}", style: _valueStyle),
                const SizedBox(height: 12),

                Text("🗓 Scheduled Pickup:", style: _labelStyle),
                Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(pickup.scheduleDate),
                  style: _valueStyle,
                ),
                const SizedBox(height: 12),

                Text("📅 Created:", style: _labelStyle),
                Text(DateFormat('MMM d, yyyy • h:mm a').format(pickup.createdAt),
                    style: _valueStyle),
                const SizedBox(height: 12),

                Text("🕓 Last Updated:", style: _labelStyle),
                Text(DateFormat('MMM d, yyyy • h:mm a').format(pickup.updatedAt),
                    style: _valueStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle =>
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  TextStyle get _valueStyle => const TextStyle(fontSize: 16);
}
