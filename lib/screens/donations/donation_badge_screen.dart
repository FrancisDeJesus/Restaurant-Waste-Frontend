import 'package:flutter/material.dart';

class DonationBadgeScreen extends StatelessWidget {
  const DonationBadgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentBadge = 'Silver Contributor';

    return Scaffold(
      appBar: AppBar(title: const Text('Donation Badge')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 100),
            const SizedBox(height: 16),
            Text(
              currentBadge,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Earn more by contributing to active drives!'),
          ],
        ),
      ),
    );
  }
}
