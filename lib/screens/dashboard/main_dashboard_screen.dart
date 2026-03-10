// lib/screens/main_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:restaurant_frontend/screens/analytics/waste_analytics_dashboard_screen.dart';
import 'package:restaurant_frontend/screens/subscriptions/subscription_dashboard_screen.dart';
import 'package:restaurant_frontend/screens/trash_pickups/trash_pickup_form_screen.dart';
import '../../services/api/auth_api.dart';
import '../../services/api/analytics_api.dart';
import '../../services/api/rewards_api.dart';
import '../../services/api/trash_pickups_api.dart';
import '../employees/employees_list_screen.dart';
import '../auth/login_screen.dart';
import '../rewards/rewards_list_screen.dart';
import '../settings/profile_screen.dart';

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

  bool _loading = true;
  bool _loadingAnalytics = true;
  bool _loadingPoints = true;
  bool _loadingPickupStats = true;

  double _totalVolume = 0.0;
  double _todayWaste = 0.0;
  double _efficiencyScore = 0.0;

  int _rewardPoints = 0;
  int _monthlyPickupCount = 0;
  int _pendingPickupCount = 0;
  String? _error;

  late AnimationController _animationController;
  late Animation<int> _pointsAnimation;

  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pointsAnimation = IntTween(begin: 0, end: 0).animate(_animationController);

    _loadProfile();
    _loadAnalytics();
    _loadPoints();
    _loadPickupStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ===== DATA LOADERS ========================================================

  Future<void> _loadProfile() async {
    try {
      final data = await AuthApi.getProfile();
      setState(() {
        _username =
            (data['restaurant_name']?.toString().trim().isNotEmpty ?? false)
            ? data['restaurant_name']
            : (data['username'] ?? '');
        _email = data['email'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
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
      final volumeData = await AnalyticsApi.getVolumeAnalytics();
      final todayWaste = await AnalyticsApi.getTodayWaste();
      final efficiency = await AnalyticsApi.getEfficiencyScore();

      setState(() {
        _totalVolume = volumeData.totalVolume;
        _todayWaste = todayWaste;
        _efficiencyScore = efficiency;
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
      _pointsAnimation = IntTween(
        begin: _rewardPoints,
        end: newPoints,
      ).animate(_animationController);
      _animationController.forward(from: 0);
      setState(() => _rewardPoints = newPoints);
    } catch (_) {
      // ignore
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

  Future<void> _loadPickupStats() async {
    setState(() => _loadingPickupStats = true);
    try {
      final pickups = await TrashPickupsApi.getAll();
      final now = DateTime.now();
      final monthlyCount = pickups.where((p) {
        final d = p.createdAt;
        return d.year == now.year && d.month == now.month;
      }).length;
      final pendingCount = pickups.where((p) => p.status == 'pending').length;

      if (!mounted) return;
      setState(() {
        _monthlyPickupCount = monthlyCount;
        _pendingPickupCount = pendingCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _monthlyPickupCount = 0;
        _pendingPickupCount = 0;
      });
    } finally {
      if (mounted) setState(() => _loadingPickupStats = false);
    }
  }

  // ===== UI ==================================================================

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      drawer: _buildDrawer(green),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        iconTheme: const IconThemeData(color: green),
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Hello, ${_username.isEmpty ? 'User' : _username}! 👋',
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: green, size: 26),
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
                await _loadPickupStats();
              },
              child: _buildDashboardBody(green, screenWidth),
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
      bottomNavigationBar: _buildBottomNav(green),
    );
  }

  // Main body (responsive)
  Widget _buildDashboardBody(Color green, double screenWidth) {
    final isWide = screenWidth > 600;
    final cardWidth = screenWidth * (isWide ? 0.3 : 0.86);

    return CustomScrollView(
      slivers: [
        // KPI Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildKpiCard(
                    "Today’s Waste Summary",
                    _formatKg(_todayWaste),
                    "Collected Today",
                    Colors.green.shade700,
                    'assets/trash.png',
                    cardWidth,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    "Monthly Analytics",
                    _formatKg(_totalVolume),
                    "Total Waste (Month)",
                    Colors.teal.shade700,
                    'assets/analytics.png',
                    cardWidth,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    "Efficiency Score",
                    _formatPct(_efficiencyScore),
                    "Segregation Accuracy",
                    Colors.orange.shade700,
                    'assets/resto_eff.png',
                    cardWidth,
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _QuickStatsCard(
              loading: _loadingPickupStats,
              monthlyPickupCount: _monthlyPickupCount,
              pendingPickupCount: _pendingPickupCount,
            ),
          ),
        ),

        // Points Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

        // Feature list (simple, responsive)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                _FeatureCard(
                  title: 'Book a Trash Pick Up',
                  subtitle: 'Schedule one today!',
                  imagePath: 'assets/trash.png',
                  bg: green,
                  fg: Colors.white,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrashPickupDashboardScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  title: 'Rewards',
                  subtitle: 'Earn & redeem points',
                  imagePath: 'assets/Rewards.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RewardsListScreen(userPoints: _rewardPoints),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  title: 'Subscription',
                  subtitle: 'Manage your plans',
                  imagePath: 'assets/subscription.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionsDashboardScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  title: 'Employees',
                  subtitle: 'Manage your staff',
                  imagePath: 'assets/employee.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployeesListScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  title: 'Donation Drives',
                  subtitle: 'Contribute surplus food',
                  imagePath: 'assets/donation.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DonationsDashboardScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  title: 'Waste Analytics',
                  subtitle: 'View performance reports',
                  imagePath: 'assets/analytics.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WasteAnalyticsDashboardScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tappable KPI card builder
  Widget _buildKpiCard(
    String title,
    String value,
    String subtitle,
    Color color,
    String img,
    double cardWidth,
  ) {
    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WasteAnalyticsDashboardScreen(),
          ),
        ),
        child: _KpiCard(
          title: title,
          value: value,
          subtitle: subtitle,
          color: color,
          imagePath: img,
        ),
      ),
    );
  }

  // Drawer
  Drawer _buildDrawer(Color green) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF015704),
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _username.isEmpty ? "Welcome!" : _username,
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email.isEmpty ? "example@email.com" : _email,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _drawerTile(
              Icons.home_rounded,
              "Home",
              () => Navigator.pop(context),
              green,
            ),
            _drawerTile(Icons.analytics_rounded, "Waste Analytics", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WasteAnalyticsDashboardScreen(),
                ),
              );
            }, green),
            _drawerTile(Icons.card_giftcard_rounded, "Rewards", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RewardsListScreen(userPoints: _rewardPoints),
                ),
              );
            }, green),
            _drawerTile(Icons.restaurant_menu_rounded, "Food Menu", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FoodMenuDashboardScreen(),
                ),
              );
            }, green),
            _drawerTile(
              Icons.volunteer_activism_rounded,
              "Donation Drives",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DonationsDashboardScreen(),
                  ),
                );
              },
              green,
            ),
            _drawerTile(Icons.subscriptions_rounded, "Subscriptions", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionsDashboardScreen(),
                ),
              );
            }, green),
            const Divider(height: 1, thickness: 0.6),
            _drawerTile(
              Icons.logout_rounded,
              "Logout",
              _logout,
              Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  // Bottom nav
  BottomAppBar _buildBottomNav(Color green) {
    return BottomAppBar(
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
                    builder: (_) => const TrashPickupListScreen(),
                  ),
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
                    builder: (_) => const EmployeesListScreen(),
                  ),
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
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              activeColor: green,
            ),
          ],
        ),
      ),
    );
  }
}

// ===== HELPERS & SUBWIDGETS ==================================================

String _formatKg(double? kg) =>
    kg == null ? "— kg" : "${kg.toStringAsFixed(1)} kg";
String _formatPct(double? pct) =>
    pct == null ? "—%" : "${pct.toStringAsFixed(1)}%";

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final String imagePath;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Container(
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 13 : 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 20 : 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: isSmall ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Image
          Image.asset(
            imagePath,
            width: isSmall ? 55 : 75,
            height: isSmall ? 55 : 75,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final Color green;
  final Animation<int> pointsAnimation;
  final AnimationController controller;
  final VoidCallback onViewRewards;

  const _PointsCard({
    required this.green,
    required this.pointsAnimation,
    required this.controller,
    required this.onViewRewards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final pts = pointsAnimation.value;
          final progress = (pts % 100) / 100.0;
          final remaining = 100 - (pts % 100);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text/progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$pts POINTS",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$remaining more points to Bronze Trophy",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Image.asset(
                'assets/trophy.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  final bool loading;
  final int monthlyPickupCount;
  final int pendingPickupCount;

  const _QuickStatsCard({
    required this.loading,
    required this.monthlyPickupCount,
    required this.pendingPickupCount,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pickups this month: $monthlyPickupCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pendingPickupCount > 0
                        ? Colors.orange.withOpacity(0.12)
                        : Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingPickupCount pending',
                    style: TextStyle(
                      color: pendingPickupCount > 0
                          ? Colors.orange.shade800
                          : green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final VoidCallback onTap;
  final Color? bg;
  final Color? fg;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imagePath,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final isAccent = bg != null && fg != null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isAccent ? bg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imagePath != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(imagePath!, fit: BoxFit.contain),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isAccent ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isAccent ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? activeColor
        : const Color.fromARGB(115, 126, 86, 86);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
