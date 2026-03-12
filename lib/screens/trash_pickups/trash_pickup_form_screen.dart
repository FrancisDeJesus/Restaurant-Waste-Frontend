import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _actualWeightController = TextEditingController();
  late String _wasteType;
  late String _address;
  late String _estimatedSize;
  late double _estimatedWeightKg;
  double? _actualWeightKg;
  DateTime _scheduleDate = DateTime.now();
  bool _saving = false;
  bool _loadingAddress = false;
  bool _scheduleLater = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _proofPhoto;
  Uint8List? _proofPhotoBytes;

  bool _loadingRecommendation = true;
  double? _weeklyWasteKg;
  String? _recommendedFrequency;

  final List<Map<String, String>> _wasteChoices = const [
    {'value': 'kitchen', 'label': 'Kitchen Waste'},
    {'value': 'food', 'label': 'Food Waste'},
    {'value': 'customer', 'label': 'Customer Waste'},
  ];

  final Map<String, double> _estimateWeightMap = const {
    'small': 3,
    'medium': 10,
    'large': 20,
    'very_large': 40,
  };

  final List<Map<String, String>> _estimateOptions = const [
    {'key': 'small', 'label': 'Small (0-5 kg)'},
    {'key': 'medium', 'label': 'Medium (5-15 kg)'},
    {'key': 'large', 'label': 'Large (15-30 kg)'},
    {'key': 'very_large', 'label': 'Very Large (30kg+)'},
  ];

  final Map<String, ({double min, double? max})> _estimateRanges = const {
    'small': (min: 0, max: 5),
    'medium': (min: 5, max: 15),
    'large': (min: 15, max: 30),
    'very_large': (min: 30, max: null),
  };

  @override
  void initState() {
    super.initState();
    _wasteType = widget.pickup?.wasteType ?? 'kitchen';
    _address = widget.pickup?.address ?? '';
    _estimatedWeightKg =
        widget.pickup?.estimatedWeightKg ?? widget.pickup?.weightKg ?? 10.0;
    _actualWeightKg = widget.pickup?.actualWeightKg ?? widget.pickup?.weightKg;
    if (_actualWeightKg != null && _actualWeightKg! > 0) {
      _actualWeightController.text = _actualWeightKg!.toStringAsFixed(1);
    }
    _estimatedSize = _mapWeightToEstimateKey(_estimatedWeightKg);
    _scheduleDate = widget.pickup?.scheduleDate ?? DateTime.now();
    if (widget.pickup == null) _fetchRestaurantAddress();
    _loadRecommendedPickupSchedule();
  }

  @override
  void dispose() {
    _actualWeightController.dispose();
    super.dispose();
  }

  String _mapWeightToEstimateKey(double weight) {
    if (weight <= 5) return 'small';
    if (weight <= 15) return 'medium';
    if (weight <= 30) return 'large';
    return 'very_large';
  }

  Future<void> _pickProofPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _proofPhoto = picked;
        _proofPhotoBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick photo: $e')));
    }
  }

  Future<void> _showPhotoSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProofPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProofPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchRestaurantAddress() async {
    setState(() => _loadingAddress = true);
    try {
      final profile = await AuthApi.getProfile();
      setState(() => _address = profile['address'] ?? '');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(' Failed to load address: $e')));
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _loadRecommendedPickupSchedule() async {
    setState(() {
      _loadingRecommendation = true;
    });

    try {
      final activePickups = await TrashPickupsApi.getAll();
      List<TrashPickup> pickupHistory = const [];

      try {
        pickupHistory = await TrashPickupsApi.getHistory();
      } catch (_) {
        // If history endpoint is unavailable, continue with active records only.
      }

      final records = _mergeUniquePickups(activePickups, pickupHistory);
      final weeklyWaste = _calculateWeeklyWasteKg(records);

      if (!mounted) return;
      setState(() {
        _weeklyWasteKg = weeklyWaste;
        _recommendedFrequency =
            weeklyWaste == null ? null : _frequencyFromWeeklyWaste(weeklyWaste);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weeklyWasteKg = null;
        _recommendedFrequency = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingRecommendation = false;
      });
    }
  }

  List<TrashPickup> _mergeUniquePickups(
    List<TrashPickup> active,
    List<TrashPickup> history,
  ) {
    final merged = <TrashPickup>[];
    final seenIds = <int>{};

    for (final pickup in [...active, ...history]) {
      final id = pickup.id;
      if (id == null) {
        merged.add(pickup);
        continue;
      }
      if (seenIds.add(id)) {
        merged.add(pickup);
      }
    }

    return merged;
  }

  double? _calculateWeeklyWasteKg(List<TrashPickup> records) {
    if (records.isEmpty) return null;

    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));

    final recentRecords = records
        .where(
          (pickup) =>
              pickup.createdAt.isAfter(fourWeeksAgo) &&
              pickup.status != 'cancelled',
        )
        .toList();

    if (recentRecords.length < 2) return null;

    final totalRecentWaste = recentRecords.fold<double>(0, (sum, pickup) {
      final weight = pickup.actualWeightKg ?? pickup.estimatedWeightKg ?? pickup.weightKg;
      return sum + (weight > 0 ? weight : 0);
    });

    if (totalRecentWaste <= 0) return null;

    return totalRecentWaste / 4;
  }

  String _frequencyFromWeeklyWaste(double weeklyWasteKg) {
    if (weeklyWasteKg > 100) {
      return 'Every 2 days';
    }
    if (weeklyWasteKg > 50) {
      return 'Every 3 days';
    }
    return 'Weekly pickup';
  }

  Widget _buildRecommendedScheduleCard() {
    const green = Color(0xFF015704);

    return Container(
      width: double.infinity,
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
      child: _loadingRecommendation
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Generating recommendation...'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_repeat_rounded, color: green),
                    SizedBox(width: 8),
                    Text(
                      'Recommended Pickup Schedule',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_weeklyWasteKg == null || _recommendedFrequency == null)
                  const Text(
                    'Not enough waste history yet to generate a pickup recommendation.',
                    style: TextStyle(color: Colors.black87, height: 1.35),
                  )
                else ...[
                  Text(
                    'Based on your recent waste data, your restaurant generates around ${_weeklyWasteKg!.toStringAsFixed(1)} kg of waste per week.',
                    style: const TextStyle(color: Colors.black87, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Suggested pickup frequency: $_recommendedFrequency.',
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
    );
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
    if (widget.pickup == null && _proofPhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a proof photo before submitting.'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _saving = true);

    try {
      final pickup = TrashPickup(
        id: widget.pickup?.id,
        wasteType: _wasteType,
        wasteTypeDisplay: '',
        weightKg: _actualWeightKg ?? _estimatedWeightKg,
        estimatedWeightKg: _estimatedWeightKg,
        actualWeightKg: _actualWeightKg,
        address: _address,
        status: 'pending',
        scheduleDate: _scheduleDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.pickup == null) {
        await TrashPickupsApi.create(
          pickup,
          proofImageBytes: _proofPhotoBytes,
          proofImageFilename: _proofPhoto?.name,
        );
      } else {
        await TrashPickupsApi.update(pickup);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Trash pickup saved successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
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
                    _buildRecommendedScheduleCard(),
                    const SizedBox(height: 12),

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
                          _buildDropdown(),
                          _buildEstimatedWeightOptions(),
                          _buildActualWeightField(),
                          _buildPhotoProofField(),
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
                                  icon: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: green,
                                  ),
                                  onPressed: _pickScheduleDateTime,
                                ),
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
                            letterSpacing: 0.3,
                          ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Waste Type',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: _wasteChoices
            .map(
              (choice) => DropdownMenuItem<String>(
                value: choice['value'],
                child: Row(
                  children: [
                    Icon(
                      _wasteTypeIcon(choice['value']!),
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(choice['label']!),
                  ],
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (_) {
          return _wasteChoices
              .map(
                (choice) => Row(
                  children: [
                    Icon(
                      _wasteTypeIcon(choice['value']!),
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(choice['label']!),
                  ],
                ),
              )
              .toList();
        },
        onChanged: (v) => setState(() => _wasteType = v ?? 'kitchen'),
      ),
    );
  }

  IconData _wasteTypeIcon(String value) {
    switch (value) {
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'food':
        return Icons.fastfood_outlined;
      case 'customer':
        return Icons.person_outline;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildEstimatedWeightOptions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Estimated Waste Volume',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: Icon(Icons.scale_outlined, color: Colors.grey[700]),
        ),
        child: Column(
          children: _estimateOptions.map((option) {
            return RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: option['key']!,
              groupValue: _estimatedSize,
              title: Text(option['label']!),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _estimatedSize = value;
                  _estimatedWeightKg = _estimateWeightMap[value] ?? 10;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActualWeightField() {
    final warning = _buildRangeWarning();
    final currentWeight = double.tryParse(_actualWeightController.text.trim());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _actualWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Actual Waste Weight (kg)',
              hintText: 'e.g. 8.3',
              helperText: 'Enter the measured weight using the provided scale.',
              prefixIcon: Icon(
                Icons.monitor_weight_outlined,
                color: Colors.grey[700],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              final input = value?.trim() ?? '';
              if (input.isEmpty)
                return 'Please enter the actual measured weight';
              final parsed = double.tryParse(input);
              if (parsed == null) return 'Please enter a valid number';
              if (parsed <= 0) return 'Weight must be greater than zero';
              return null;
            },
            onSaved: (value) {
              _actualWeightKg = double.tryParse(value?.trim() ?? '');
            },
            onChanged: (_) => setState(() {}),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (currentWeight != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Selected Range: ${_selectedEstimateLabel()}\nActual Weight: ${currentWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _selectedEstimateLabel() {
    return _estimateOptions.firstWhere(
      (item) => item['key'] == _estimatedSize,
      orElse: () => {'label': 'Selected range'},
    )['label']!;
  }

  String? _buildRangeWarning() {
    final currentWeight = double.tryParse(_actualWeightController.text.trim());
    if (currentWeight == null) return null;

    final range = _estimateRanges[_estimatedSize];
    if (range == null) return null;

    final isWithinMin = currentWeight >= range.min;
    final isWithinMax = range.max == null || currentWeight <= range.max!;
    if (isWithinMin && isWithinMax) return null;

    return 'Weight does not match ${_selectedEstimateLabel()}. You can still submit if this is correct.';
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

  Widget _buildPhotoProofField() {
    const green = Color(0xFF015704);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo Proof (Waste Bin)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_proofPhotoBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _proofPhotoBytes!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Text(
                'No photo selected yet. Upload one as proof of segregation.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _proofPhotoBytes == null ? 'Upload Photo' : 'Replace Photo',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                  ),
                  onPressed: _showPhotoSourcePicker,
                ),
              ),
              if (_proofPhotoBytes != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: () {
                    setState(() {
                      _proofPhoto = null;
                      _proofPhotoBytes = null;
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
