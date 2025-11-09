import 'package:flutter/material.dart';
import '../../../screens/trash_pickups/trash_pickup_model.dart';
import '../../../services/api/trash_pickups_api.dart';
import '../../../services/api/auth_api.dart';

class TrashPickupFormScreen extends StatefulWidget {
  final TrashPickup? pickup;
  const TrashPickupFormScreen({super.key, this.pickup});

  @override
  State<TrashPickupFormScreen> createState() => _TrashPickupFormScreenState();
}

class _TrashPickupFormScreenState extends State<TrashPickupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _wasteType;
  late String _address;
  late double _weightKg;
  DateTime _scheduleDate = DateTime.now();
  bool _saving = false;
  bool _loadingAddress = false;

  final List<Map<String, String>> _wasteChoices = const [
    {'value': 'kitchen', 'label': 'Kitchen Waste'},
    {'value': 'food', 'label': 'Food Waste'},
    {'value': 'customer', 'label': 'Customer Waste'},
  ];

  @override
  void initState() {
    super.initState();
    _wasteType = widget.pickup?.wasteType ?? 'kitchen';
    _address = widget.pickup?.address ?? '';
    _weightKg = widget.pickup?.weightKg ?? 0.0;
    _scheduleDate = widget.pickup?.scheduleDate ?? DateTime.now();

    if (widget.pickup == null) {
      _fetchRestaurantAddress();
    }
  }

  Future<void> _fetchRestaurantAddress() async {
    setState(() => _loadingAddress = true);
    try {
      final profile = await AuthApi.getProfile();
      setState(() {
        _address = profile['address'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load address: $e')),
      );
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _pickScheduleDateTime() async {
    // Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduleDate),
    );

    if (pickedTime == null) return;

    setState(() {
      _scheduleDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);

    try {
      final pickup = TrashPickup(
        id: widget.pickup?.id,
        wasteType: _wasteType,
        wasteTypeDisplay: '',
        weightKg: _weightKg,
        address: _address,
        status: 'pending',
        scheduleDate: _scheduleDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.pickup == null) {
        await TrashPickupsApi.create(pickup);
      } else {
        await TrashPickupsApi.update(pickup);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Trash pickup saved successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickup == null ? 'Request Trash Pickup' : 'Edit Trash Pickup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingAddress
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    
                    TextFormField(
                      initialValue: _address,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Address (Registered)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Address is required' : null,
                      onSaved: (v) => _address = v!.trim(),
                    ),
                    const SizedBox(height: 12),                    
                    
                    DropdownButtonFormField<String>(
                      value: _wasteType,
                      decoration: const InputDecoration(labelText: 'Waste Type'),
                      items: _wasteChoices
                          .map((choice) => DropdownMenuItem(
                                value: choice['value'],
                                child: Text(choice['label']!),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _wasteType = v!),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: _weightKg > 0 ? _weightKg.toString() : '',
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter weight' : null,
                      onSaved: (v) => _weightKg = double.tryParse(v!) ?? 0.0,
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Scheduled Pickup'),
                      subtitle: Text(
                        "${_scheduleDate.year}-${_scheduleDate.month.toString().padLeft(2, '0')}-${_scheduleDate.day.toString().padLeft(2, '0')} "
                        "at ${_scheduleDate.hour.toString().padLeft(2, '0')}:${_scheduleDate.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _pickScheduleDateTime,
                      ),
                    ),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Pickup'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
