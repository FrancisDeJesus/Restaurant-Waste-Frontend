import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:restaurant_frontend/screens/analytics/waste_analytics_dashboard_screen.dart';
import 'package:restaurant_frontend/screens/subscriptions/subscription_dashboard_screen.dart';
import 'package:restaurant_frontend/screens/trash_pickups/trash_pickup_form_screen.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/analytics_api.dart';
import '../../services/api/rewards_api.dart';
import '../employees/employees_list_screen.dart';
import '../auth/login_screen.dart';
import '../rewards/rewards_list_screen.dart';
import '../trash_pickups/trash_pickup_dashboard_screen';
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

  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
      _pointsAnimation =
          IntTween(begin: _rewardPoints, end: newPoints).animate(_animationController);
      _animationController.forward(from: 0);
      setState(() {
        _rewardPoints = newPoints;
      });
    } catch (e) {
      if (!mounted) return;
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
    final green = const Color(0xFF015704);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await _loadAnalytics();
                await _loadPoints();
              },
              child: CustomScrollView(
                slivers: [
                  // HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      child: _Header(
                        name: _username.isEmpty ? 'User' : _username,
                        green: green,
                        onLogout: _logout,
                      ),
                    ),
                  ),

                  // SEARCH BAR
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _RoundIcon(icon: Icons.menu_rounded, onTap: () {}),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: const [
                                  Icon(Icons.search, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Search...', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // REWARD POINTS CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _loadingPoints
                          ? const Center(child: CircularProgressIndicator())
                          : _PointsCard(
                              green: green,
                              pointsAnimation: _pointsAnimation,
                              controller: _animationController,
                              onViewRewards: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RewardsListScreen(userPoints: _rewardPoints),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // FEATURE GRID
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: isWide ? 1.2 : 1,
                        children: [
                          _FeatureCard(
                            title: 'Book a Trash Pick Up',
                            subtitle: 'Schedule one today!',
                            icon: Icons.local_shipping_rounded,
                            bg: green,
                            fg: Colors.white,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrashPickupDashboardScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Rewards',
                            subtitle: 'Earn & redeem',
                            icon: Icons.card_giftcard_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RewardsListScreen(userPoints: _rewardPoints),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Subscription',
                            subtitle: 'View plan details',
                            icon: Icons.subscriptions_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionsDashboardScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Employees',
                            subtitle: 'Manage your staff',
                            icon: Icons.group_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EmployeesListScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SHOW MORE BUTTON → opens bottom sheet
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Center(
                        child: SizedBox(
                          width: 180,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (_) => _MoreModulesSheet(green: green),
                              );
                            },
                            child: const Text(
                              'Show More',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrashPickupFormScreen()),
          );
        },
        child: const Icon(Icons.local_shipping_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
                activeColor: green,
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Map',
                selected: _navIndex == 1,
                onTap: () {
                  setState(() => _navIndex = 1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TrashPickupListScreen()),
                  );
                },
                activeColor: green,
              ),
              const SizedBox(width: 48),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Employees',
                selected: _navIndex == 3,
                onTap: () {
                  setState(() => _navIndex = 3);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployeesListScreen()),
                  );
                },
                activeColor: green,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: _navIndex == 4,
                onTap: () {
                  setState(() => _navIndex = 4);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FoodMenuDashboardScreen()),
                  );
                },
                activeColor: green,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==== CHART HELPERS ====

  Widget _buildPieChart() {
    final total = _byType.values.fold(0.0, (a, b) => a + b);
    final sections = _byType.entries.map((entry) {
      final percent = total == 0 ? 0 : (entry.value / total) * 100;
      final color = Colors.primaries[
          _byType.keys.toList().indexOf(entry.key) % Colors.primaries.length];
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 72,
        title: "${entry.key}\n${percent.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Waste Type Distribution",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
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

  Widget _buildBarChart() {
    final entries = _byMonth.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Monthly Waste Volume (kg)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
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
                        final i = value.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            entries[i].key.split(" ")[0],
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

// ==== COMPONENTS ====

class _Header extends StatelessWidget {
  final String name;
  final Color green;
  final VoidCallback onLogout;
  const _Header({required this.name, required this.green, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFECEFF1)),
          child: const Icon(Icons.person, color: Colors.black54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Hello, $name!',
              style:
                  TextStyle(color: green, fontWeight: FontWeight.w800, fontSize: 26)),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.black54),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: Colors.black54),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final Color green;
  final Animation<int> pointsAnimation;
  final AnimationController controller;
  final VoidCallback onViewRewards;
  const _PointsCard(
      {required this.green,
      required this.pointsAnimation,
      required this.controller,
      required this.onViewRewards});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: green, width: 3),
        boxShadow: [
          BoxShadow(color: green.withOpacity(0.12), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final pts = pointsAnimation.value;
              final progress = (pts % 100) / 100.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$pts POINTS',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8F2E8),
                        color: green),
                  ),
                  const SizedBox(height: 6),
                  const Text('Keep earning to unlock rewards!',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: onViewRewards,
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child:
                          Text('View Rewards', style: TextStyle(color: green)),
                    ),
                  )
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: double.infinity,
          width: 72,
          decoration: BoxDecoration(
              color: const Color(0xFFF9F5E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEDFAF))),
          child: const Center(
              child: Icon(Icons.emoji_events_rounded,
                  size: 40, color: Colors.amber)),
        ),
      ]),
    );
  }
}

class _AnalyticsPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  const _AnalyticsPill(
      {required this.icon,
      required this.color,
      required this.title,
      required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 6, spreadRadius: 2)
        ],
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 13)),
          ],
        )),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? bg;
  final Color? fg;
  const _FeatureCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap,
      this.bg,
      this.fg});
  @override
  Widget build(BuildContext context) {
    final isAccent = bg != null && fg != null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isAccent ? bg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.more_vert,
                  color: isAccent ? Colors.white70 : Colors.black38)),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: isAccent ? Colors.white24 : const Color(0xFFF0F2F2),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: isAccent ? Colors.white : Colors.black87),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isAccent ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: isAccent ? Colors.white70 : Colors.black54)),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
      required this.activeColor});
  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : const Color.fromARGB(115, 126, 86, 86);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 11))
            ]),
      ),
    );
  }
}

// =================== MODAL SHEET FOR "SHOW MORE" ===================

class _MoreModulesSheet extends StatelessWidget {
  final Color green;
  const _MoreModulesSheet({required this.green});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'icon': Icons.volunteer_activism_rounded,
        'title': 'Donation Drives',
        'desc': 'Organize and monitor donation campaigns',
        'route': const DonationsDashboardScreen(),
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Food Menu',
        'desc': 'Track inventory and manage ingredients',
        'route': const FoodMenuDashboardScreen(),
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Waste Analytics',
        'desc': 'View insights and reports on waste trends',
        'route': const WasteAnalyticsDashboardScreen(),
      },
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Container(
                width: 45,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const Text("More Modules",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: modules.length,
                  itemBuilder: (context, i) {
                    final m = modules[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m['icon'] as IconData, color: green),
                      ),
                      title: Text(m['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text(m['desc'] as String,
                          style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => m['route'] as Widget),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}