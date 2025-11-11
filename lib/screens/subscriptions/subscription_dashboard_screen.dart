// lib/screens/subscriptions/subscriptions_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'subscription_plans_screen.dart';
import 'subscription_active_screen.dart';
import 'subscription_history_screen.dart';

class SubscriptionsDashboardScreen extends StatefulWidget {
  const SubscriptionsDashboardScreen({super.key});

  @override
  State<SubscriptionsDashboardScreen> createState() =>
      _SubscriptionsDashboardScreenState();
}

class _SubscriptionsDashboardScreenState
    extends State<SubscriptionsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color green = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabButton(String text, int index) {
    final bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: green, width: 1.3),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: green.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : green,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SUBSCRIPTIONS",
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton("Active Plan", 0),
                  const SizedBox(width: 10),
                  _buildTabButton("Available", 1),
                  const SizedBox(width: 10),
                  _buildTabButton("History", 2),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // ✅ The active card itself (left-aligned) lives here
          SubscriptionActiveScreen(),
          SubscriptionPlansScreen(),
          SubscriptionHistoryScreen(),
        ],
      ),
    );
  }
}
