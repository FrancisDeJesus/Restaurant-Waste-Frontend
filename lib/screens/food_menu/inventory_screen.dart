import 'package:flutter/material.dart';
import '../../services/api/ingredient_api.dart';
import '../../services/api/unit_type_api.dart';
import '../../models/food/ingredient_model.dart';
import '../../models/food/unit_type_model.dart';
import 'ingredient_history_screen.dart'; // ✅ Import the history screen

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

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  // ======================================================
  // 🔄 LOAD INGREDIENTS + UNIT TYPES
  // ======================================================
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

  // ======================================================
  // ➕ ADD NEW INGREDIENT
  // ======================================================
  Future<void> _addIngredientDialog() async {
    _nameController.clear();
    _quantityController.clear();
    _selectedUnitType = null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name'),
              ),
              DropdownButtonFormField<UnitType>(
                decoration: const InputDecoration(labelText: 'Unit Type'),
                value: _selectedUnitType,
                items: _unitTypes
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text('${unit.name} (${unit.abbreviation})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedUnitType = val),
              ),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                  'quantity':
                      double.tryParse(_quantityController.text) ?? 0.0,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingredient added!')),
                  );
                  _loadInventory();
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Failed to add: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // ✏️ EDIT QUANTITY
  // ======================================================
  Future<void> _editQuantityDialog(Ingredient ingredient) async {
    final controller =
        TextEditingController(text: ingredient.quantity.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${ingredient.name} Quantity'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Quantity (${ingredient.unitTypeAbbreviation})',
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                      const SnackBar(content: Text('Quantity updated!')));
                  _loadInventory();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🗑️ DELETE INGREDIENT
  // ======================================================
  Future<void> _deleteIngredient(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Delete "$name" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await IngredientApi.deleteIngredient(id);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingredient "$name" deleted.')));
      _loadInventory();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  // ======================================================
  // 🖥️ UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadInventory, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInventory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _stock.length,
          itemBuilder: (context, index) {
            final item = _stock[index];
            final isLowStock = item.quantity <= _lowStockThreshold;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
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
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isLowStock ? Colors.redAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
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
                                fontWeight: FontWeight.bold),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
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
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIngredientDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Ingredient'),
      ),
    );
  }
}
