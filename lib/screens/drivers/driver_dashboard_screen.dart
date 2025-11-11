import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api/auth_api.dart';
import '../auth/login_screen.dart';
import 'driver_assigned_pickups_screen.dart';
import 'driver_available_pickups_screen.dart';
import 'driver_history_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final int driverId;

  const DriverDashboardScreen({super.key, required this.driverId});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  static const Color green = Color(0xFF015704);
  int _selectedIndex = 0;
  String _driverName = 'Driver';
  Map<String, dynamic>? _availablePickup;
  bool _loadingPickup = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
    _fetchAvailablePickup();
  }

  // ======================================================
  // 🧾 DRIVER PROFILE
  // ======================================================
  Future<void> _loadDriverProfile() async {
    try {
      final data = await AuthApi.getProfile();
      final user = data['user'] is Map ? data['user'] : {};
      if (!mounted) return;
      setState(() {
        _driverName = user['username'] ??
            data['full_name'] ??
            data['role']?.toUpperCase() ??
            'Driver';
      });
    } catch (e) {
      debugPrint("⚠️ Failed to load driver profile: $e");
    }
  }

  // ======================================================
  // 🚚 FETCH DRIVER’S AVAILABLE PICKUP
  // ======================================================
  Future<void> _fetchAvailablePickup() async {
    setState(() {
      _loadingPickup = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get("drivers/available/");
      debugPrint("📦 API body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List pickups = [];
        if (data is List) {
          pickups = data;
        } else if (data is Map && data['results'] != null) {
          pickups = data['results'];
        } else if (data is Map && data['available_pickups'] != null) {
          pickups = data['available_pickups'];
        }

        if (!mounted) return;
        setState(() {
          _availablePickup = pickups.isNotEmpty ? pickups.first : null;
          _errorMessage = pickups.isEmpty ? "No available pickups yet." : null;
        });
      } else if (response.statusCode == 403) {
        setState(() => _errorMessage =
            "⚠️ Access Denied: You are not authorized to view this data.");
      } else if (response.statusCode == 404) {
        // ✅ Instead of showing 404, show user-friendly message
        setState(() => _errorMessage = "No available pickups yet.");
      } else {
        setState(() => _errorMessage =
            "Unexpected error: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to load pickups: $e");
    } finally {
      if (mounted) setState(() => _loadingPickup = false);
    }
  }

  // ======================================================
  // ✅ ACCEPT PICKUP FUNCTION
  // ======================================================
  Future<void> _acceptPickup() async {
    if (_availablePickup == null) return;

    final pickupId = _availablePickup!['id'];
    debugPrint("🚀 Accepting pickup ID: $pickupId");

    try {
      final response = await ApiService.patch(
        "drivers/${widget.driverId}/accept/",
        {"pickup_id": pickupId},
      );

      debugPrint("📬 Accept response: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Pickup accepted successfully!"),
            backgroundColor: Colors.green.shade700,
          ),
        );
        await _fetchAvailablePickup();
        setState(() => _selectedIndex = 1);
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ Failed: ${err['detail'] ?? err['error'] ?? 'Unknown error'}",
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Accept error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Error: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // ======================================================
  // 🚪 LOGOUT
  // ======================================================
  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ======================================================
  // 🏠 HOME SCREEN (Available Pickups as Current Activity)
  // ======================================================
  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _fetchAvailablePickup,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // HEADER
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFECEFF1),
                radius: 22,
                child: Icon(Icons.person, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Hello, $_driverName!",
                  style: const TextStyle(
                    color: green,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.black54),
                tooltip: "Logout",
                onPressed: _logout,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            "Available Pickup",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          if (_loadingPickup)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: green),
              ),
            )
          else if (_errorMessage != null)
            _buildEmptyState(_errorMessage!)
          else
            _buildAvailablePickupCard(),

          const SizedBox(height: 28),

          // GRID SECTION
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureCard(
                title: "Past Deliveries",
                subtitle: "View your completed trips",
                icon: Icons.history_rounded,
                color: green,
                filled: true,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _buildFeatureCard(
                title: "Rewards",
                subtitle: "Earn and redeem points",
                icon: Icons.card_giftcard_rounded,
                onTap: () {},
              ),
              _buildFeatureCard(
                title: "Payments",
                subtitle: "View transactions",
                icon: Icons.account_balance_wallet_rounded,
                onTap: () {},
              ),
              _buildFeatureCard(
                title: "Cash Out",
                subtitle: "Withdraw earnings",
                icon: Icons.attach_money_rounded,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // VIEW ALL PICKUPS BUTTON
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () =>
                  setState(() => _selectedIndex = 2), // Go to Available list
              child: const Text(
                "View All Available Pickups",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🟩 EMPTY STATE CARD
  // ======================================================
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🟩 AVAILABLE PICKUP CARD
  // ======================================================
  Widget _buildAvailablePickupCard() {
    final wasteType = _availablePickup?['waste_type'] ?? "Unknown Waste";
    final address = _availablePickup?['address'] ?? "No address available";
    final restaurant =
        _availablePickup?['restaurant_name'] ?? "Restaurant Partner";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.local_shipping_rounded, color: green, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wasteType,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    Text(restaurant,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                    Text(address,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _acceptPickup,
              child: const Text(
                "Accept Pickup",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 💡 FEATURE CARD BUILDER
  // ======================================================
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? color,
    bool filled = false,
    required VoidCallback onTap,
  }) {
    final bg = filled ? (color ?? green) : Colors.white;
    final fg = filled ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.more_vert, color: fg.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white24
                    : const Color(0xFFF0F2F2).withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: fg, size: 24),
            ),
            const Spacer(),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: fg, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12, color: fg.withOpacity(0.8), height: 1.2)),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // MAIN BUILD
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeScreen(),
      DriverAssignedPickupsScreen(driverId: widget.driverId),
      DriverAvailablePickupsScreen(driverId: widget.driverId),
      DriverHistoryScreen(driverId: widget.driverId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded), label: 'Assigned'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_rounded), label: 'Available'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), label: 'History'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        onPressed: () => setState(() => _selectedIndex = 2),
        child: const Icon(Icons.local_shipping_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
