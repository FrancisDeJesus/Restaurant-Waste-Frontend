import 'package:flutter/material.dart';
import 'active_donation_drives_screen.dart';
import 'donation_history_screen.dart';
import 'donation_info_screen.dart';
import 'donation_badge_screen.dart';

class DonationsDashboardScreen extends StatelessWidget {
  const DonationsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'DONATION DRIVES',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _DonationCard(
              icon: Icons.volunteer_activism_rounded,
              title: 'Active Donation Drives',
              color: green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ActiveDonationDrivesScreen()),
              ),
            ),
            _DonationCard(
              icon: Icons.history_rounded,
              title: 'Donation History',
              color: Colors.orange.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
              ),
            ),
            _DonationCard(
              icon: Icons.info_outline_rounded,
              title: 'Information Page',
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationInfoScreen()),
              ),
            ),
            _DonationCard(
              icon: Icons.emoji_events_rounded,
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
