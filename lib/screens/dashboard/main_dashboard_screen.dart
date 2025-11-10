import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/analytics_api.dart';
import '../../services/api/rewards_api.dart';
import '../employees/employees_list_screen.dart';
import '../auth/login_screen.dart';
import '../rewards/rewards_list_screen.dart';
import '../trash_pickups/trash_pickup_list_screen.dart';
import '../donations/donation_dashboard_screen.dart';
import '../food_menu/food_menu_dashboard_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _username = '';
  String _email = '';
  String _restaurant = '';
  bool _loading = true;
  bool _loadingAnalytics = true;
  bool _loadingPoints = true;
  double _totalVolume = 0.0;
  int _rewardPoints = 0;
  Map<String, double> _byType = {};
  Map<String, double> _byMonth = {};
  String? _error;

  late AnimationController _animationController;
  late Animation<int> _pointsAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Safe initialization to prevent LateInitializationError
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pointsAnimation = IntTween(begin: 0, end: 0).animate(_animationController);

    _loadProfile();
    _loadAnalytics();
    _loadPoints();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await AuthApi.getProfile();
      setState(() {
        _username = data['username'] ?? '';
        _email = data['email'] ?? '';
        _restaurant = data['restaurant_name'] ?? 'My Restaurant';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loadingAnalytics = true;
      _error = null;
    });

    try {
      final data = await AnalyticsApi.getVolumeAnalytics();
      setState(() {
        _totalVolume = data.totalVolume;
        _byType = data.byType;
        _byMonth = data.byMonth;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingAnalytics = false);
    }
  }

  Future<void> _loadPoints() async {
    setState(() => _loadingPoints = true);
    try {
      final data = await RewardsApi.getUserPoints();
      final newPoints = (data['total_points'] ?? 0) as int;

      if (!mounted) return;

      // animate from old to new
      _pointsAnimation = IntTween(begin: _rewardPoints, end: newPoints)
          .animate(_animationController);
      _animationController.forward(from: 0);

      setState(() {
        _rewardPoints = newPoints;
      });

      // optional: show debug
      // debugPrint("✅ Points updated to $newPoints");
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error loading reward points: $e');
      // Optional UX: show a one-time snackbar
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Failed to load points')),
      // );
    } finally {
      if (mounted) setState(() => _loadingPoints = false);
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
    final isWide = MediaQuery.of(context).size.width > 600;

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
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await _loadAnalytics();
                await _loadPoints();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 👋 Welcome
                  Text(
                    'Hello, $_username 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Monitor all your activities here",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // 💰 Reward Points Card
                  if (_loadingPoints)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade600, Colors.orange.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final animatedValue =
                                    _pointsAnimation.value.toString();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Reward Points",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "$animatedValue pts",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RewardsListScreen(userPoints: _rewardPoints),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("View Rewards"),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ♻️ Waste Summary
                  if (_loadingAnalytics)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Text("Error loading analytics: $_error",
                        style: const TextStyle(color: Colors.red))
                  else if (_byType.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _byType.entries.map((entry) {
                          final type = entry.key.toLowerCase();
                          final volume = entry.value;
                          IconData icon;
                          Color color;
                          String subtitle;

                          switch (type) {
                            case "recyclable":
                              icon = Icons.recycling;
                              color = Colors.blueAccent;
                              subtitle = "Contribute to sustainability";
                              break;
                            case "food":
                              icon = Icons.delete_outline;
                              color = Colors.grey.shade700;
                              subtitle = "Manage your general waste";
                              break;
                            case "biodegradable":
                              icon = Icons.eco_outlined;
                              color = Colors.green;
                              subtitle = "Keep the environment clean";
                              break;
                            case "hazardous":
                              icon = Icons.warning_amber_rounded;
                              color = Colors.redAccent;
                              subtitle = "Handle with care";
                              break;
                            default:
                              icon = Icons.category;
                              color = Colors.teal;
                              subtitle = "Waste overview";
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _AnalyticsCard(
                              title: entry.key,
                              value: "${volume.toStringAsFixed(1)}kg",
                              subtitle: subtitle,
                              icon: icon,
                              color: color,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Charts
                  if (_byType.isNotEmpty && _byMonth.isNotEmpty)
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPieChart()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildBarChart()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPieChart(),
                              const SizedBox(height: 20),
                              _buildBarChart(),
                            ],
                          ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 🧩 Dashboard Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _DashboardCard(
                        icon: Icons.group,
                        title: 'Employees',
                        subtitle: 'Manage staff records',
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
                        subtitle: 'Track collection schedules',
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
                        subtitle: 'View and redeem rewards',
                        color: Colors.blue.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RewardsListScreen(userPoints: _rewardPoints),
                          ),
                        ),
                      ),
                      _DashboardCard(
                        icon: Icons.favorite,
                        title: 'Donation Drives',
                        subtitle: 'Join community programs',
                        color: Colors.pink.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DonationsDashboardScreen(),
                          ),
                        ),
                      ),
                      _DashboardCard(
                        icon: Icons.restaurant_menu,
                        title: 'Food Menu',
                        subtitle: 'Manage menu and inventory',
                        color: Colors.teal.shade700,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FoodMenuDashboardScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // 🥧 Pie Chart
  Widget _buildPieChart() {
    final total = _byType.values.fold(0.0, (a, b) => a + b);
    final sections = _byType.entries.map((entry) {
      final percent = (entry.value / total) * 100;
      final color = Colors.primaries[
          _byType.keys.toList().indexOf(entry.key) % Colors.primaries.length];
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 70,
        title: "${entry.key}\n${percent.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        children: [
          const Text(
            "Waste Type Distribution",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Bar Chart
  Widget _buildBarChart() {
    final entries = _byMonth.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        children: [
          const Text(
            "Monthly Waste Volume (kg)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            entries[index].key.split(" ")[0],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value,
                        width: 18,
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _chartBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          spreadRadius: 1,
          blurRadius: 5,
        )
      ],
    );
  }
}

// 🔹 Analytics Summary Card
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// 🔹 Dashboard Main Card
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
