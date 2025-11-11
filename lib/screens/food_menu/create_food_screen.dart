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
  final _servingsController = TextEditingController(text: "1");

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
          'unit_type': ingredient.unitTypeId,
        });
      }
    });
  }

  void _updateIngredientQuantity(int id, double newQuantity) {
    setState(() {
      final index =
          _selectedIngredients.indexWhere((item) => item['ingredient'] == id);
      if (index != -1) {
        _selectedIngredients[index]['quantity_used'] = newQuantity;
      }
    });
  }

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

  double _parseFraction(String input) {
    input = input.trim();
    double result = 0.0;

    try {
      if (input.contains(' ')) {
        final parts = input.split(' ');
        final whole = double.tryParse(parts[0]) ?? 0.0;
        final fraction = parts[1].split('/');
        if (fraction.length == 2) {
          final num = double.tryParse(fraction[0]) ?? 0.0;
          final den = double.tryParse(fraction[1]) ?? 1.0;
          result = whole + (num / den);
        }
      } else if (input.contains('/')) {
        final parts = input.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]) ?? 0.0;
          final den = double.tryParse(parts[1]) ?? 1.0;
          result = num / den;
        }
      } else {
        result = double.tryParse(input) ?? 0.0;
      }
    } catch (_) {
      result = 0.0;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    }

    final servings = int.tryParse(_servingsController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    final pricePerServing = servings > 0 ? (price / servings) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          // ↑ Added top padding for breathing space
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✨ Page header text
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create New Food Item',
                    style: TextStyle(
                      color: green,
                      fontSize: 26, // larger for emphasis
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 🧾 Form Fields
                _textField('Food Name', _nameController, green,
                    validator: true, icon: Icons.fastfood),
                _textField('Description', _descController, green,
                    maxLines: 2, icon: Icons.notes),
                _textField('Total Price (₱)', _priceController, green,
                    keyboardType: TextInputType.number,
                    validator: true,
                    icon: Icons.price_change),
                _textField('Category', _categoryController, green,
                    icon: Icons.category),
                _textField('Servings (number of portions)', _servingsController,
                    green,
                    keyboardType: TextInputType.number,
                    validator: true,
                    icon: Icons.restaurant_menu),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '💡 ₱${pricePerServing.toStringAsFixed(2)} per serving',
                    style: const TextStyle(color: green),
                  ),
                ),
                const SizedBox(height: 24),

                // 🍅 Ingredient Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Ingredients (and set quantity)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: green,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients.map((ingredient) {
                    final selected = _selectedIngredients
                        .any((i) => i['ingredient'] == ingredient.id);
                    return ChoiceChip(
                      label: Text(ingredient.name),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      selectedColor: green,
                      backgroundColor: Colors.grey.shade200,
                      selected: selected,
                      onSelected: (_) => _toggleIngredient(ingredient),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 🔢 Quantity Fields
                if (_selectedIngredients.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedIngredients.map((item) {
                      final ingredient = _ingredients
                          .firstWhere((i) => i.id == item['ingredient']);
                      final selectedUnitId = item['unit_type'];
                      final controller = TextEditingController(
                        text: item['quantity_used']?.toString() ?? '0.0',
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                ingredient.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                value: selectedUnitId,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                ),
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

                const SizedBox(height: 30),
                _submitting
                    ? const Center(
                        child: CircularProgressIndicator(color: green))
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _submitForm,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            'Save Food',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, Color color,
      {bool validator = false,
      IconData? icon,
      TextInputType keyboardType = TextInputType.text,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null ? Icon(icon, color: color) : const SizedBox(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
        ),
        validator: validator
            ? (v) => v == null || v.isEmpty ? 'Required field' : null
            : null,
      ),
    );
  }
}
