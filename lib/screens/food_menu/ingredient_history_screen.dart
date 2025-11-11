import 'package:flutter/material.dart';
import '../../services/api/ingredient_api.dart';
import '../../models/food/ingredient_history_model.dart';

class IngredientHistoryScreen extends StatefulWidget {
  final int ingredientId;
  final String ingredientName;

  const IngredientHistoryScreen({
    super.key,
    required this.ingredientId,
    required this.ingredientName,
  });

  @override
  State<IngredientHistoryScreen> createState() =>
      _IngredientHistoryScreenState();
}

class _IngredientHistoryScreenState extends State<IngredientHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<IngredientHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data =
          await IngredientApi.getIngredientHistory(widget.ingredientId);
      setState(() {
        _history = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'added':
        return const Color(0xFF2E7D32); // Green
      case 'deducted':
        return const Color(0xFFC62828); // Red
      case 'used_in_recipe':
        return const Color(0xFFF9A825); // Yellow
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'added':
        return Icons.add_circle_outline;
      case 'deducted':
        return Icons.remove_circle_outline;
      case 'used_in_recipe':
        return Icons.restaurant_menu;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: green));
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_history.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      color: green,
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final h = _history[i];
          final color = _getColor(h.changeType);
          final icon = _getIcon(h.changeType);
          final dateTime = DateTime.tryParse(h.timestamp);
          final date = dateTime != null
              ? "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}"
              : h.timestamp;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              title: Text(
                "${h.changeType.toUpperCase()} ${h.amount} ${h.unit}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  h.note?.isNotEmpty == true
                      ? h.note!
                      : "No description provided",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
              trailing: Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 📄 Empty View
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          children: [
            Image.asset('assets/no_data.png', height: 140),
            const SizedBox(height: 20),
            const Text(
              "No history records found for this ingredient.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⚠️ Error View
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 10),
            const Text(
              "Error loading ingredient history",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? "Unknown error occurred.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015704),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
