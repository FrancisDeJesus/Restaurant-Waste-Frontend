// lib/screens/food_menu/inventory_screen.dart
import 'package:flutter/material.dart';
import '../../services/api/ingredient_api.dart';
import '../../services/api/unit_type_api.dart';
import '../../models/food/ingredient_model.dart';
import '../../models/food/unit_type_model.dart';
import 'ingredient_history_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Ingredient> _stock = [];
  List<UnitType> _unitTypes = [];
  bool _loading = true;
  String? _error;

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  UnitType? _selectedUnitType;

  static const double _lowStockThreshold = 2.0;
  static const green = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await IngredientApi.getIngredients();
      final units = await UnitTypeApi.getUnitTypes();
      setState(() {
        _stock = data;
        _unitTypes = units;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ➕ ADD INGREDIENT DIALOG
  Future<void> _addIngredientDialog() async {
    _nameController.clear();
    _quantityController.clear();
    _selectedUnitType = null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Ingredient',
          style: TextStyle(fontWeight: FontWeight.bold, color: green),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(_nameController, 'Ingredient Name', Icons.fastfood),
              const SizedBox(height: 8),
              DropdownButtonFormField<UnitType>(
                decoration: InputDecoration(
                  labelText: 'Unit Type',
                  prefixIcon: const Icon(Icons.straighten, color: green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedUnitType,
                items: _unitTypes
                    .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text('${unit.name} (${unit.abbreviation})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedUnitType = val),
              ),
              const SizedBox(height: 8),
              _inputField(_quantityController, 'Quantity', Icons.balance,
                  isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (_nameController.text.isEmpty ||
                  _selectedUnitType == null ||
                  _quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required')),
                );
                return;
              }
              try {
                await IngredientApi.createIngredient({
                  'name': _nameController.text,
                  'unit_type': _selectedUnitType!.id,
                  'quantity': double.tryParse(_quantityController.text) ?? 0.0,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Ingredient added!')),
                  );
                  _loadInventory();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ✏️ EDIT QUANTITY DIALOG
  Future<void> _editQuantityDialog(Ingredient ingredient) async {
    final controller =
        TextEditingController(text: ingredient.quantity.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit ${ingredient.name} Quantity',
          style: const TextStyle(fontWeight: FontWeight.bold, color: green),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Quantity (${ingredient.unitTypeAbbreviation})',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: green),
            onPressed: () async {
              try {
                final payload = {
                  'name': ingredient.name,
                  'unit_type': ingredient.unitTypeId,
                  'quantity': double.tryParse(controller.text) ?? 0.0,
                };
                await IngredientApi.updateIngredient(ingredient.id, payload);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Quantity updated!')));
                  _loadInventory();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  // 🗑️ DELETE INGREDIENT
  Future<void> _deleteIngredient(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Ingredient',
          style: TextStyle(fontWeight: FontWeight.bold, color: green),
        ),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await IngredientApi.deleteIngredient(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ "$name" deleted from inventory.')),
      );
      _loadInventory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⚠️ $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadInventory,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: green),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: green,
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stock.length,
        itemBuilder: (context, index) {
          final item = _stock[index];
          final isLowStock = item.quantity <= _lowStockThreshold;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLowStock ? Colors.redAccent : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IngredientHistoryScreen(
                      ingredientId: item.id,
                      ingredientName: item.name,
                    ),
                  ),
                );
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red[800] : Colors.black,
                      ),
                    ),
                  ),
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LOW STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                'Available: ${item.quantity} ${item.unitTypeAbbreviation}',
                style: TextStyle(
                  color: isLowStock ? Colors.red[700] : Colors.grey[700],
                ),
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit Quantity',
                    onPressed: () => _editQuantityDialog(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Ingredient',
                    onPressed: () => _deleteIngredient(item.id, item.name),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType:
          isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
      ),
    );
  }
}
