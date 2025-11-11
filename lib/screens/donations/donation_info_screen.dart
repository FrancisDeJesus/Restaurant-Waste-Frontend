import 'package:flutter/material.dart';

class DonationInfoScreen extends StatelessWidget {
  const DonationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: green),
        title: const Text(
          'DONATION INFORMATION',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌿 HEADER IMAGE OR ICON
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: green,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Making a Difference Together 💚",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "DARWCOS Donation Drives empower restaurants to support "
                "sustainability through community-oriented waste initiatives.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 HOW IT WORKS SECTION
            const Text(
              "🌱 How It Works",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: green,
              ),
            ),
            const SizedBox(height: 10),
            _infoStep(
              icon: Icons.recycling,
              title: "1. Collect Reusable Waste",
              description:
                  "Gather your restaurant's recyclable or reusable materials such as plastic, food scraps, or kitchen waste.",
            ),
            _infoStep(
              icon: Icons.add_box_rounded,
              title: "2. Join an Active Drive",
              description:
                  "Browse the list of active donation drives that match your waste type and choose where to contribute.",
            ),
            _infoStep(
              icon: Icons.done_all_rounded,
              title: "3. Complete Your Donation",
              description:
                  "Once your pickup is completed, donate it to your selected drive through the DARWCOS app.",
            ),
            const SizedBox(height: 30),

            // 🎖️ REWARDS SECTION
            const Text(
              "🎖️ Earn Badges and Points",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: green,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: green.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: green, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "Each successful donation contributes points toward your "
                      "Donation Badge — climb from Bronze to Gold as you give more!",
                      style: TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ❤️ CTA FOOTER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    "“Your waste can spark change.”",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Join a donation drive today and make an impact in your community.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper widget for steps
  Widget _infoStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    const green = Color(0xFF015704);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: green, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
