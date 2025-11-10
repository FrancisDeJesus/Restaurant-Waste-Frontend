import 'package:flutter/material.dart';

class RedeemedHistoryScreen extends StatelessWidget {
  const RedeemedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redemption History')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.history, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Redemption tracking is not yet available.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              SizedBox(height: 10),
              Text(
                "Once point redemption features are added, you'll see your history here.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
