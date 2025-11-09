// lib/screens/dashboard/main_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/api/auth_api.dart';
import '../employees/employees_list_screen.dart';
import '../auth/login_screen.dart';
import '../rewards/rewards_list_screen.dart';
import '../trash_pickups/trash_pickup_list_screen.dart';
import '../donations/donation_dashboard_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  String _username = '';
  String _email = '';
  String _restaurant = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await AuthApi.getProfile();
      setState(() {
        _username = data['username'] ?? '';
        _email = data['email'] ?? '';
        _restaurant = data['restaurant_name'] ?? 'My Restaurant';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  Text(
                    'Welcome, $_username 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _restaurant,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Grid of dashboard cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _DashboardCard(
                          icon: Icons.group,
                          title: 'Employees',
                          color: Colors.green.shade700,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmployeesListScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          icon: Icons.recycling,
                          title: 'Waste Pickups',
                          color: Colors.orange.shade700,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TrashPickupListScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          icon: Icons.card_giftcard,
                          title: 'Rewards',
                          color: Colors.blue.shade700,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RewardsListScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          icon: Icons.favorite,
                          title: 'Donation Drives', // ✅ NEW
                          color: Colors.pink.shade700,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DonationsDashboardScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          icon: Icons.analytics_outlined,
                          title: 'Reports',
                          color: Colors.deepPurple.shade700,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reports module coming soon...'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// =============================
// 🔹 Dashboard Card Widget
// =============================
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
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
