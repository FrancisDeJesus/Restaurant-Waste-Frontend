import 'package:flutter/material.dart';
import '../../services/api/food_api.dart';
import '../../models/food/food_item_model.dart';
import 'edit_food_screen.dart';

class CurrentMenuScreen extends StatefulWidget {
  const CurrentMenuScreen({super.key});

  @override
  State<CurrentMenuScreen> createState() => _CurrentMenuScreenState();
}

class _CurrentMenuScreenState extends State<CurrentMenuScreen> {
  List<FoodItem> _menu = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  // =========================================================
  // 🔄 Load Menu from API
  // =========================================================
  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await FoodApi.getFoods();
      setState(() => _menu = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // =========================================================
  // ✏️ Navigate to Edit Screen
  // =========================================================
  Future<void> _openEditScreen(FoodItem food) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFoodScreen(food: food),
      ),
    );
    if (updated == true) {
      _loadMenu(); // Refresh after returning
    }
  }

  // =========================================================
  // 🗑️ Delete Menu Item
  // =========================================================
  Future<void> _deleteFood(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: const Text('Are you sure you want to delete this food item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FoodApi.deleteFood(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food deleted successfully!')),
      );
      _loadMenu();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  // =========================================================
  // 🖥️ UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading menu: $_error',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMenu,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_menu.isEmpty) {
      return const Center(child: Text('No food items yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadMenu,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _menu.length,
        itemBuilder: (context, index) {
          final food = _menu[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                food.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(food.description ?? 'No description'),
              trailing: Text(
                '₱${food.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              children: [
                if (food.ingredients.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: food.ingredients.map((i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${i.ingredientName} — ${i.quantityUsed} unit(s)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No ingredients listed.'),
                  ),
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Item',
                        onPressed: () => _openEditScreen(food),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Item',
                        onPressed: () => _deleteFood(food.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
