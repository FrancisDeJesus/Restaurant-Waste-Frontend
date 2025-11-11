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
  bool _scheduleLater = false;

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
    if (widget.pickup == null) _fetchRestaurantAddress();
  }

  Future<void> _fetchRestaurantAddress() async {
    setState(() => _loadingAddress = true);
    try {
      final profile = await AuthApi.getProfile();
      setState(() => _address = profile['address'] ?? '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load address: $e')),
      );
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
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
    const green = Color(0xFF015704);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pick Up Details',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _loadingAddress
          ? const Center(child: CircularProgressIndicator(color: green))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICK UP DETAILS',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🧾 Form Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Pick Up Address',
                            value: _address,
                            icon: Icons.location_on_outlined,
                            readOnly: true,
                          ),
                          _buildTextField(
                            label: 'Weight of Trash',
                            hint: 'Enter the weight (kg)',
                            icon: Icons.scale_outlined,
                            keyboardType: TextInputType.number,
                            initialValue:
                                _weightKg > 0 ? _weightKg.toString() : '',
                            onSaved: (v) =>
                                _weightKg = double.tryParse(v ?? '0') ?? 0.0,
                          ),
                          _buildDropdown(),
                          _buildRadioOptions(),
                          if (_scheduleLater)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${_scheduleDate.year}-${_scheduleDate.month.toString().padLeft(2, '0')}-${_scheduleDate.day.toString().padLeft(2, '0')} "
                                    "at ${_scheduleDate.hour.toString().padLeft(2, '0')}:${_scheduleDate.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_month_rounded,
                                      color: green),
                                  onPressed: _pickScheduleDateTime,
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? 'Saving...' : 'Set Pick Up',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper UI methods
  Widget _buildTextField({
    required String label,
    String? value,
    String? hint,
    IconData? icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? initialValue,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: readOnly,
        initialValue: value ?? initialValue,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[700]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (v) =>
            v == null || v.isEmpty ? 'Please fill out this field' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _wasteType,
        decoration: InputDecoration(
          labelText: 'Waste Type',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: _wasteChoices
            .map((choice) => DropdownMenuItem(
                  value: choice['value'],
                  child: Text(choice['label']!),
                ))
            .toList(),
        onChanged: (v) => setState(() => _wasteType = v ?? 'kitchen'),
      ),
    );
  }

  Widget _buildRadioOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<bool>(
          value: false,
          groupValue: _scheduleLater,
          title: const Text('Pick up now'),
          onChanged: (val) => setState(() => _scheduleLater = val!),
        ),
        RadioListTile<bool>(
          value: true,
          groupValue: _scheduleLater,
          title: const Text('Schedule a time'),
          onChanged: (val) => setState(() => _scheduleLater = val!),
        ),
      ],
    );
  }
}
