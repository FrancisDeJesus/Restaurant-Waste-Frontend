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
      setState(() {
        _unitTypes = units;
      });
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
        const SnackBar(content: Text('Unit type added successfully!')),
      );
      _loadUnits();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _deleteUnitType(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit Type'),
        content: const Text('Are you sure you want to delete this unit type?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      await UnitTypeApi.deleteUnitType(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully!')),
      );
      _loadUnits();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadUnits, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Unit Types',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Name (e.g. Kilogram)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _abbrController,
                  decoration: const InputDecoration(
                    labelText: 'Abbreviation (e.g. kg)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _submitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _addUnitType,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _unitTypes.length,
              itemBuilder: (context, index) {
                final unit = _unitTypes[index];
                return Card(
                  child: ListTile(
                    title: Text(unit.name),
                    subtitle: Text(unit.abbreviation.isNotEmpty
                        ? unit.abbreviation
                        : 'No abbreviation'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
