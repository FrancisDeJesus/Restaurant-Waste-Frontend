// lib/screens/food_menu/create_food_screen.dart
import 'package:flutter/material.dart';
import '../../services/api/food_api.dart';
import '../../services/api/ingredient_api.dart';
import '../../services/api/unit_type_api.dart';
import '../../models/food/ingredient_model.dart';
import '../../models/food/unit_type_model.dart';

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _servingsController = TextEditingController(text: "1"); // ✅ Default 1 serving

  List<Ingredient> _ingredients = [];
  List<UnitType> _unitTypes = [];
  List<Map<String, dynamic>> _selectedIngredients = [];

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ======================================================
  // 🔄 Load Ingredients and Unit Types
  // ======================================================
  Future<void> _loadData() async {
    try {
      final ingredients = await IngredientApi.getIngredients();
      final units = await UnitTypeApi.getUnitTypes();
      setState(() {
        _ingredients = ingredients;
        _unitTypes = units;
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  // ======================================================
  // ✅ Toggle Ingredient Selection
  // ======================================================
  void _toggleIngredient(Ingredient ingredient) {
    final exists =
        _selectedIngredients.any((item) => item['ingredient'] == ingredient.id);

    setState(() {
      if (exists) {
        _selectedIngredients
            .removeWhere((item) => item['ingredient'] == ingredient.id);
      } else {
        _selectedIngredients.add({
          'ingredient': ingredient.id,
          'ingredient_name': ingredient.name,
          'quantity_used': 0.0,
          'unit_type': ingredient.unitTypeId, // default to inventory unit
        });
      }
    });
  }

  // ======================================================
  // ✏️ Update Quantity
  // ======================================================
  void _updateIngredientQuantity(int id, double newQuantity) {
    setState(() {
      final index =
          _selectedIngredients.indexWhere((item) => item['ingredient'] == id);
      if (index != -1) {
        _selectedIngredients[index]['quantity_used'] = newQuantity;
      }
    });
  }

  // ======================================================
  // 💾 Submit Form to Backend
  // ======================================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final payload = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'category': _categoryController.text,
      'servings': int.tryParse(_servingsController.text) ?? 1,
      'food_ingredients': List<Map<String, dynamic>>.from(
        _selectedIngredients.map((i) => {
              'ingredient': i['ingredient'] as int,
              'quantity_used': (i['quantity_used'] as num).toDouble(),
              'unit_type': i['unit_type'] ?? 0,
            }),
      ),
    };

    print('🧾 Sending payload: $payload');

    try {
      await FoodApi.createFood(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Food added successfully!')),
      );
      _formKey.currentState!.reset();
      _selectedIngredients.clear();
      _servingsController.text = "1";
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save food: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  // ======================================================
  // 🔢 Parse fraction string to decimal
  // ======================================================
  double _parseFraction(String input) {
    input = input.trim();
    double result = 0.0;

    try {
      // Example: "2 1/2"
      if (input.contains(' ')) {
        final parts = input.split(' ');
        final whole = double.tryParse(parts[0]) ?? 0.0;
        final fraction = parts[1].split('/');
        if (fraction.length == 2) {
          final num = double.tryParse(fraction[0]) ?? 0.0;
          final den = double.tryParse(fraction[1]) ?? 1.0;
          result = whole + (num / den);
        } else {
          result = whole;
        }
      }
      // Example: "1/4"
      else if (input.contains('/')) {
        final parts = input.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]) ?? 0.0;
          final den = double.tryParse(parts[1]) ?? 1.0;
          result = num / den;
        }
      }
      // Example: "2.5"
      else {
        result = double.tryParse(input) ?? 0.0;
      }
    } catch (_) {
      result = 0.0;
    }

    return result;
  }

  // ======================================================
  // 🖥️ UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final servings = int.tryParse(_servingsController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    final pricePerServing = servings > 0 ? (price / servings) : 0;

    return Padding(
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
              decoration: const InputDecoration(labelText: 'Total Price'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Enter price' : null,
              onChanged: (_) => setState(() {}),
            ),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextFormField(
              controller: _servingsController,
              decoration: const InputDecoration(
                  labelText: 'Servings (number of portions this recipe makes)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Enter servings' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              '💡 ₱${pricePerServing.toStringAsFixed(2)} per serving',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Ingredients (and set quantity)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: _ingredients.map((ingredient) {
                final selected = _selectedIngredients
                    .any((i) => i['ingredient'] == ingredient.id);
                return ChoiceChip(
                  label: Text(ingredient.name),
                  selected: selected,
                  onSelected: (_) => _toggleIngredient(ingredient),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ======================================================
            // Ingredient Quantity + Unit Selection
            // ======================================================
            if (_selectedIngredients.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedIngredients.map((item) {
                  final ingredient = _ingredients
                      .firstWhere((i) => i.id == item['ingredient']);

                  final selectedUnitId = item['unit_type'];
                  final selectedUnit = _unitTypes.firstWhere(
                    (u) => u.id == selectedUnitId,
                    orElse: () => _unitTypes.first,
                  );

                  final controller = TextEditingController(
                    text: item['quantity_used']?.toString() ?? '0.0',
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(ingredient.name)),
                        const SizedBox(width: 8),

                        // 🔽 Dropdown for Unit Type
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            value: selectedUnitId,
                            decoration:
                                const InputDecoration(labelText: 'Unit'),
                            items: _unitTypes.map((u) {
                              return DropdownMenuItem<int>(
                                value: u.id,
                                child: Text(u.abbreviation),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                item['unit_type'] = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ✏️ Quantity Field (auto convert fraction)
                        Expanded(
                          flex: 2,
                          child: Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) {
                                final parsed =
                                    _parseFraction(controller.text.trim());
                                controller.text = parsed.toString();
                                _updateIngredientQuantity(
                                    ingredient.id, parsed);
                              }
                            },
                            child: TextFormField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration:
                                  const InputDecoration(labelText: 'Qty'),
                              onChanged: (v) {
                                final parsed = _parseFraction(v);
                                _updateIngredientQuantity(
                                    ingredient.id, parsed);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),
            _submitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Food'),
                  ),
          ],
        ),
      ),
    );
  }
}
