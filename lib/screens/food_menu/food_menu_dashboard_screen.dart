import 'package:flutter/material.dart';
import 'create_food_screen.dart';
import 'current_menu_screen.dart';
import 'inventory_screen.dart';
import 'unit_types_screen.dart'; // ✅ NEW IMPORT

class FoodMenuDashboardScreen extends StatefulWidget {
  const FoodMenuDashboardScreen({super.key});

  @override
  State<FoodMenuDashboardScreen> createState() =>
      _FoodMenuDashboardScreenState();
}

class _FoodMenuDashboardScreenState extends State<FoodMenuDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'Create New Menu', icon: Icon(Icons.add_circle_outline)),
    Tab(text: 'Current Menu', icon: Icon(Icons.list_alt)),
    Tab(text: 'Inventory / Stock', icon: Icon(Icons.inventory)),
    Tab(text: 'Unit Types', icon: Icon(Icons.straighten)), // ✅ NEW TAB
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

  void _goToCreateTab() {
    _tabController.animateTo(0); // Switch to "Create New Menu" tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Menu Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CreateFoodScreen(),
          CurrentMenuScreen(),
          InventoryScreen(),
          UnitTypesScreen(), // ✅ NEW TAB CONTENT
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _goToCreateTab,
              icon: const Icon(Icons.add),
              label: const Text('Add Food'),
              backgroundColor: Colors.teal,
            ),
    );
  }
}
