// lib/screens/food_menu/edit_food_screen.dart
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
    _descController =
        TextEditingController(text: widget.food.description ?? '');
    _priceController =
        TextEditingController(text: widget.food.price.toString());
    _categoryController =
        TextEditingController(text: widget.food.category ?? '');
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
            'unit_type': i.unitTypeId,
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _toggleIngredient(Ingredient ingredient) {
    setState(() {
      final exists = _selectedIngredients
          .any((item) => item['ingredient'] == ingredient.id);

      if (exists) {
        _selectedIngredients
            .removeWhere((item) => item['ingredient'] == ingredient.id);
      } else {
        _selectedIngredients.add({
          'ingredient': ingredient.id,
          'ingredient_name': ingredient.name,
          'quantity_used': 0.0,
          'unit_type': ingredient.unitTypeId ?? 0,
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
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'category': _categoryController.text.trim(),
      'food_ingredients': _selectedIngredients.map((i) {
        return {
          'ingredient': i['ingredient'],
          'quantity_used': i['quantity_used'],
          'unit_type': i['unit_type'],
        };
      }).toList(),
    };

    try {
      await FoodApi.updateFood(widget.food.id, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Food updated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: green),
        title: const Text(
          'EDIT FOOD ITEM',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _textField('Food Name', _nameController, green,
                    icon: Icons.fastfood, validator: true),
                _textField('Description', _descController, green,
                    maxLines: 2, icon: Icons.notes),
                _textField('Price (₱)', _priceController, green,
                    keyboardType: TextInputType.number, icon: Icons.price_change),
                _textField('Category', _categoryController, green,
                    icon: Icons.category),
                const SizedBox(height: 20),

                // 🍅 Ingredient Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ingredients',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: green,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allIngredients.map((ingredient) {
                    final selected = _selectedIngredients
                        .any((i) => i['ingredient'] == ingredient.id);
                    return ChoiceChip(
                      label: Text(ingredient.name),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      selected: selected,
                      selectedColor: green,
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) => _toggleIngredient(ingredient),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                if (_selectedIngredients.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedIngredients.map((i) {
                      final ing = _allIngredients
                          .firstWhere((x) => x.id == i['ingredient']);
                      final unit = _unitTypes.firstWhere(
                        (u) => u.id == ing.unitTypeId,
                        orElse: () =>
                            UnitType(id: 0, name: 'Unit', abbreviation: ''),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${ing.name} (${unit.abbreviation})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue:
                                    i['quantity_used']?.toString() ?? '0.0',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
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

                const SizedBox(height: 30),
                _saving
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
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
          prefixIcon: icon != null ? Icon(icon, color: color) : null,
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
