import 'package:flutter/material.dart';
import 'active_donation_drives_screen.dart';
import 'donation_history_screen.dart';
import 'donation_info_screen.dart';
import 'donation_badge_screen.dart';

class DonationsDashboardScreen extends StatelessWidget {
  const DonationsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Drives')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _DonationCard(
              icon: Icons.volunteer_activism,
              title: 'Active Donation Drives',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActiveDonationDrivesScreen()),
              ),
            ),
            _DonationCard(
              icon: Icons.history,
              title: 'Donation History',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
              ),
            ),
            _DonationCard(
              icon: Icons.info_outline,
              title: 'Information Page',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationInfoScreen()),
              ),
            ),
            _DonationCard(
              icon: Icons.emoji_events,
              title: 'Donation Badge',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationBadgeScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DonationCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
