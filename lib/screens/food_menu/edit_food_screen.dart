import 'package:flutter/material.dart';
import '../../services/api/food_api.dart';
import '../../services/api/ingredient_api.dart';
import '../../services/api/unit_type_api.dart';
import '../../models/food/food_item_model.dart';
import '../../models/food/ingredient_model.dart';
import '../../models/food/unit_type_model.dart';

class EditFoodScreen extends StatefulWidget {
  final FoodItem food;

  const EditFoodScreen({super.key, required this.food});

  @override
  State<EditFoodScreen> createState() => _EditFoodScreenState();
}

class _EditFoodScreenState extends State<EditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;

  List<Ingredient> _allIngredients = [];
  List<UnitType> _unitTypes = [];
  List<Map<String, dynamic>> _selectedIngredients = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.food.name);
    _descController = TextEditingController(text: widget.food.description ?? '');
    _priceController = TextEditingController(text: widget.food.price.toString());
    _categoryController = TextEditingController(text: widget.food.category ?? '');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ingredients = await IngredientApi.getIngredients();
      final units = await UnitTypeApi.getUnitTypes();

      setState(() {
        _allIngredients = ingredients;
        _unitTypes = units;

        _selectedIngredients = widget.food.ingredients.map((i) {
          return {
            'ingredient': i.ingredientId,
            'ingredient_name': i.ingredientName,
            'quantity_used': i.quantityUsed,
            'unit_type': i.unitTypeId, // ✅ keep consistent with backend
          };
        }).toList();

        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading ingredients: $e')));
    }
  }

  void _toggleIngredient(Ingredient ingredient) {
    final exists = _selectedIngredients
        .any((item) => item['ingredient'] == ingredient.id);

    setState(() {
      if (exists) {
        _selectedIngredients
            .removeWhere((item) => item['ingredient'] == ingredient.id);
      } else {
        _selectedIngredients.add({
          'ingredient': ingredient.id,
          'ingredient_name': ingredient.name,
          'quantity_used': 0.0,
          'unit_type': ingredient.unitTypeId,
        });
      }
    });
  }

  void _updateQuantity(int id, double value) {
    final index =
        _selectedIngredients.indexWhere((i) => i['ingredient'] == id);
    if (index != -1) {
      setState(() => _selectedIngredients[index]['quantity_used'] = value);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final payload = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'category': _categoryController.text,
      'food_ingredients': _selectedIngredients.map((i) {
        return {
          'ingredient': i['ingredient'],
          'quantity_used': i['quantity_used'],
        };
      }).toList(),
    };

    try {
      await FoodApi.updateFood(widget.food.id, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Food updated successfully!')),
      );
      Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Failed to update: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Menu Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Food Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingredients',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _allIngredients.map((ingredient) {
                  final selected = _selectedIngredients
                      .any((i) => i['ingredient'] == ingredient.id);
                  return ChoiceChip(
                    label: Text(ingredient.name),
                    selected: selected,
                    onSelected: (_) => _toggleIngredient(ingredient),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (_selectedIngredients.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedIngredients.map((i) {
                    final ing = _allIngredients
                        .firstWhere((x) => x.id == i['ingredient']);
                    final unit = _unitTypes.firstWhere(
                      (u) => u.id == ing.unitTypeId,
                      orElse: () => UnitType(id: 0, name: 'Unit', abbreviation: ''),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('${ing.name} (${unit.abbreviation})'),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue:
                                  i['quantity_used']?.toString() ?? '0.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Quantity'),
                              onChanged: (v) => _updateQuantity(
                                ing.id,
                                double.tryParse(v) ?? 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
