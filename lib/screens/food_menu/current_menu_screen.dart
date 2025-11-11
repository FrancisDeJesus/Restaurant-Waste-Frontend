// lib/screens/food_menu/current_menu_screen.dart
import 'package:flutter/material.dart';
import '../../services/api/food_api.dart';
import '../../models/food/food_item_model.dart';
import 'edit_food_screen.dart';
import 'create_food_screen.dart';

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

  Future<void> _openEditScreen(FoodItem food) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditFoodScreen(food: food)),
    );
    if (updated == true) {
      _loadMenu();
    }
  }

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
        const SnackBar(content: Text('✅ Food deleted successfully!')),
      );
      _loadMenu();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 12),
            Text(
              'Error loading menu:',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _loadMenu,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ No Food Items Display
    if (_menu.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/add_food.png', height: 120),
            const SizedBox(height: 16),
            const Text(
              'No food items yet.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add dishes to display them here!',
              style: TextStyle(color: green, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // ✅ Display List of Menu Items (no AppBar)
    return RefreshIndicator(
      onRefresh: _loadMenu,
      color: green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _menu.length,
        itemBuilder: (context, index) {
          final food = _menu[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: green.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  food.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: green,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    food.description?.isNotEmpty == true
                        ? food.description!
                        : 'No description available',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                trailing: Text(
                  '₱${food.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: green,
                  ),
                ),
                children: [
                  if (food.ingredients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.restaurant_menu_rounded,
                                  color: green, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "Ingredients:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...food.ingredients.map((i) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '• ${i.ingredientName} — ${i.quantityUsed} ${i.unitTypeAbbreviation ?? "unit(s)"}',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No ingredients listed.',
                          textAlign: TextAlign.left,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  const Divider(height: 10, thickness: 0.4),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue),
                          label: const Text(
                            "Edit",
                            style: TextStyle(color: Colors.blue),
                          ),
                          onPressed: () => _openEditScreen(food),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          label: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => _deleteFood(food.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
