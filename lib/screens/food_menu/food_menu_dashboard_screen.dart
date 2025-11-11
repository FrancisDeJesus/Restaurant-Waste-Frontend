import 'package:flutter/material.dart';
import 'create_food_screen.dart';
import 'current_menu_screen.dart';
import 'inventory_screen.dart';
import 'unit_types_screen.dart';

class FoodMenuDashboardScreen extends StatefulWidget {
  const FoodMenuDashboardScreen({super.key});

  @override
  State<FoodMenuDashboardScreen> createState() =>
      _FoodMenuDashboardScreenState();
}

class _FoodMenuDashboardScreenState extends State<FoodMenuDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const green = Color(0xFF015704);

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.add_circle_outline), text: 'Create Menu'),
    Tab(icon: Icon(Icons.list_alt), text: 'Current Menu'),
    Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Inventory'),
    Tab(icon: Icon(Icons.straighten), text: 'Unit Types'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToCreateTab() => _tabController.animateTo(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(115),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'FOOD MENU MANAGEMENT',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: green),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs,
            labelColor: Colors.white,
            unselectedLabelColor: green.withOpacity(0.8),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            indicator: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            splashBorderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CreateFoodScreen(),
          CurrentMenuScreen(),
          InventoryScreen(),
          UnitTypesScreen(),
        ],
      ),
    );
  }
}
