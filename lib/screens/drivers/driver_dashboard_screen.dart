// lib/screens/drivers/driver_dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // ✅ correct path to ApiService
import '../../services/api/auth_api.dart'; // ✅ correct path to AuthApi
import '../auth/login_screen.dart';
import 'driver_assigned_pickups_screen.dart';
import 'driver_available_pickups_screen.dart';
import 'driver_history_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final int driverId; // 👈 required to fetch driver-specific data

  const DriverDashboardScreen({super.key, required this.driverId});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;
  String _driverName = '';
  bool _loadingStats = true;

  int _assignedCount = 0;
  int _availableCount = 0;
  int _completedCount = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildHomeScreen(), // 🏠 Dashboard tab
      DriverAssignedPickupsScreen(driverId: widget.driverId),
      DriverAvailablePickupsScreen(driverId: widget.driverId),
      DriverHistoryScreen(driverId: widget.driverId),
    ];
    _loadDriverProfile();
    _fetchDriverStats();
  }

  // ✅ Fetch driver info (for drawer + home)
  Future<void> _loadDriverProfile() async {
    try {
      final data = await AuthApi.getProfile();
      final user = data['user'] is Map ? data['user'] : {};
      setState(() {
        _driverName = user['username'] ??
            data['full_name'] ??
            data['role']?.toUpperCase() ??
            'Driver';
      });
    } catch (_) {
      setState(() => _driverName = 'Driver');
    }
  }

  // ✅ Fetch driver statistics
  Future<void> _fetchDriverStats() async {
    setState(() => _loadingStats = true);
    try {
      final assignedRes =
          await ApiService.get("drivers/${widget.driverId}/assigned/");
      final availableRes =
          await ApiService.get("drivers/${widget.driverId}/available/");
      final historyRes =
          await ApiService.get("drivers/${widget.driverId}/history/");

      if (assignedRes.statusCode == 200 &&
          availableRes.statusCode == 200 &&
          historyRes.statusCode == 200) {
        final assignedData = jsonDecode(assignedRes.body) as List;
        final availableData = jsonDecode(availableRes.body) as List;
        final completedData = jsonDecode(historyRes.body) as List;

        setState(() {
          _assignedCount = assignedData.length;
          _availableCount = availableData.length;
          _completedCount = completedData.length;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch driver stats: $e");
    } finally {
      setState(() => _loadingStats = false);
    }
  }

  // ✅ Logout
  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ====================================================
  // 🏠 DRIVER HOME SCREEN (with live stats)
  // ====================================================
  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _fetchDriverStats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                const Icon(Icons.local_shipping,
                    size: 80, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  "Welcome, $_driverName!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Here's your current activity summary:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _loadingStats
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStatCard(
                      icon: Icons.assignment,
                      label: "Assigned Pickups",
                      value: _assignedCount,
                      color: Colors.orange.shade600,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      icon: Icons.local_shipping,
                      label: "Available Pickups",
                      value: _availableCount,
                      color: Colors.blue.shade600,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      icon: Icons.history,
                      label: "Completed Pickups",
                      value: _completedCount,
                      color: Colors.green.shade700,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),
                  ],
                ),
          const SizedBox(height: 40),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh Stats"),
            onPressed: _fetchDriverStats,
          ),
        ],
      ),
    );
  }

  // 🧱 Stat card helper widget
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 🧭 NAVIGATION
  // ====================================================
  final List<String> _titles = [
    "Driver Dashboard",
    "Assigned Pickups",
    "Available Pickups",
    "Pickup History",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_pin, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _driverName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text(
                    "Driver Dashboard",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Home'),
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Assigned Pickups'),
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Available Pickups'),
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Pickup History'),
              onTap: () => setState(() => _selectedIndex = 3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Assigned',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
