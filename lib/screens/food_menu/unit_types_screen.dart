// lib/screens/food_menu/unit_types_screen.dart
import 'package:flutter/material.dart';
import '../../services/api/unit_type_api.dart';
import '../../models/food/unit_type_model.dart';

class UnitTypesScreen extends StatefulWidget {
  const UnitTypesScreen({super.key});

  @override
  State<UnitTypesScreen> createState() => _UnitTypesScreenState();
}

class _UnitTypesScreenState extends State<UnitTypesScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<UnitType> _unitTypes = [];

  final _nameController = TextEditingController();
  final _abbrController = TextEditingController();

  static const green = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final units = await UnitTypeApi.getUnitTypes();
      setState(() => _unitTypes = units);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addUnitType() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    final body = {
      'name': _nameController.text.trim(),
      'abbreviation': _abbrController.text.trim(),
    };

    try {
      await UnitTypeApi.createUnitType(body);
      _nameController.clear();
      _abbrController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Unit type added successfully!')),
      );
      _loadUnits();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Failed to add: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _deleteUnitType(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Unit Type',
          style: TextStyle(fontWeight: FontWeight.bold, color: green),
        ),
        content: const Text('Are you sure you want to delete this unit type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await UnitTypeApi.deleteUnitType(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Deleted successfully!')),
      );
      _loadUnits();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

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
            Text('⚠️ Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadUnits,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: green),
            ),
          ],
        ),
      );
    }

    // ✅ Removed AppBar — content now sits flush under tab layout
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Manage Measurement Units',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: green,
            ),
          ),
          const SizedBox(height: 12),

          // Add Form Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Unit Name (e.g. Kilogram)',
                      prefixIcon: const Icon(Icons.straighten, color: green),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _abbrController,
                    decoration: InputDecoration(
                      labelText: 'Abbreviation (e.g. kg)',
                      prefixIcon: const Icon(Icons.text_fields, color: green),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _submitting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: CircularProgressIndicator(
                            color: green, strokeWidth: 2.5),
                      )
                    : ElevatedButton.icon(
                        onPressed: _addUnitType,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // List of Units
          Expanded(
            child: _unitTypes.isEmpty
                ? const Center(
                    child: Text(
                      'No unit types added yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    itemCount: _unitTypes.length,
                    itemBuilder: (context, index) {
                      final unit = _unitTypes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            unit.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            unit.abbreviation.isNotEmpty
                                ? unit.abbreviation
                                : 'No abbreviation',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _deleteUnitType(unit.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
