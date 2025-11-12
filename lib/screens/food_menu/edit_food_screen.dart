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
  late TextEditingController _shelfLifeController;

  List<Ingredient> _allIngredients = [];
  List<UnitType> _unitTypes = [];
  List<Map<String, dynamic>> _selectedIngredients = [];

  bool _loading = true;
  bool _saving = false;

  static const green = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.food.name);
    _descController = TextEditingController(text: widget.food.description ?? '');
    _priceController = TextEditingController(text: widget.food.price.toString());
    _categoryController = TextEditingController(text: widget.food.category ?? '');
    _shelfLifeController = TextEditingController(text: widget.food.shelfLifeDays.toString());
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
            'ingredient': i.id,
            'ingredient_name': i.name,
            'quantity_used': i.quantity,
            'unit_type': i.unitTypeId,
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  void _updateQuantity(int id, double value) {
    final index = _selectedIngredients.indexWhere((i) => i['ingredient'] == id);
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
      'shelf_life_days': int.tryParse(_shelfLifeController.text) ?? 3,
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    }

    final expireDate = widget.food.expirationDate.toLocal().toString().split(' ')[0];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: green),
        title: const Text(
          'Edit Food Item',
          style: TextStyle(color: green, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textField('Food Name', _nameController, validator: true),
                  _textField('Description', _descController, maxLines: 2),
                  _textField('Price (₱)', _priceController,
                      keyboardType: TextInputType.number),
                  _textField('Category', _categoryController),
                  _textField('Shelf Life (days)', _shelfLifeController,
                      keyboardType: TextInputType.number),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Estimated Expiration: $expireDate',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),

                  const Divider(height: 30, thickness: 0.6),

                  const Text(
                    'Ingredients',
                    style: TextStyle(fontWeight: FontWeight.bold, color: green, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allIngredients.map((ingredient) {
                      final selected = _selectedIngredients.any((i) => i['ingredient'] == ingredient.id);
                      return ChoiceChip(
                        label: Text(ingredient.name),
                        labelStyle:
                            TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13),
                        selected: selected,
                        selectedColor: green,
                        backgroundColor: Colors.grey.shade200,
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedIngredients.removeWhere((i) => i['ingredient'] == ingredient.id);
                          } else {
                            _selectedIngredients.add({
                              'ingredient': ingredient.id,
                              'ingredient_name': ingredient.name,
                              'quantity_used': 0.0,
                              'unit_type': ingredient.unitTypeId,
                            });
                          }
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  if (_selectedIngredients.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: green.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _selectedIngredients.map((i) {
                          final ing = _allIngredients.firstWhere(
                            (x) => x.id == i['ingredient'],
                            orElse: () => Ingredient(
                              id: i['ingredient'] ?? 0,
                              name: i['ingredient_name'] ?? 'Unknown Ingredient',
                              quantity: i['quantity_used'] ?? 0.0,
                              unitTypeId: i['unit_type'] ?? 0,
                              unitTypeName: 'Unknown',
                              unitTypeAbbreviation: '',
                            ),
                          );

                          final unit = _unitTypes.firstWhere(
                            (u) => u.id == ing.unitTypeId,
                            orElse: () => UnitType(id: 0, name: 'Unit', abbreviation: ''),
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${ing.name} (${unit.abbreviation})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: ing.name == 'Unknown Ingredient'
                                          ? Colors.redAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: i['quantity_used']?.toString() ?? '0.0',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (v) => _updateQuantity(
                                        ing.id, double.tryParse(v) ?? 0),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 30),
                  _saving
                      ? const Center(child: CircularProgressIndicator(color: green))
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _saveChanges,
                              label: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller,
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
          prefixIcon: icon != null ? Icon(icon, color: green) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
        validator: validator ? (v) => v == null || v.isEmpty ? 'Required field' : null : null,
      ),
    );
  }
}
