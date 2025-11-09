import 'package:flutter/material.dart';

class DonationInfoScreen extends StatelessWidget {
  const DonationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Information')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'DARWCOS Donation Drives allow restaurants to contribute reusable waste to support community initiatives. '
          'Choose a drive based on waste type (e.g., Plastic, Food, Kitchen). '
          'Each successful donation contributes points toward your Donation Badge!',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
