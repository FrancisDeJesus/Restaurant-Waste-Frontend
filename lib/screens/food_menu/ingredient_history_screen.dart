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
  State<IngredientHistoryScreen> createState() => _IngredientHistoryScreenState();
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
      final data = await IngredientApi.getIngredientHistory(widget.ingredientId);
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

  // Color logic for each change type
  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'added':
        return Colors.green;
      case 'deducted':
        return Colors.red;
      case 'used_in_recipe':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  // Icon logic for each change type
  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'added':
        return Icons.add_circle;
      case 'deducted':
        return Icons.remove_circle;
      case 'used_in_recipe':
        return Icons.restaurant_menu;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        title: Text(
          "${widget.ingredientName} History",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "⚠️ Error loading history:\n$_error",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : _history.isEmpty
                  ? const Center(
                      child: Text(
                        "No history records found for this ingredient.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (_, i) {
                          final h = _history[i];
                          final color = _getColor(h.changeType);
                          final icon = _getIcon(h.changeType);
                          final dateTime = DateTime.tryParse(h.timestamp);
                          final date = dateTime != null
                              ? "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}"
                              : h.timestamp;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left icon
                                  CircleAvatar(
                                    backgroundColor: color.withOpacity(0.15),
                                    child: Icon(icon, color: color),
                                  ),
                                  const SizedBox(width: 12),

                                  // Main info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${h.changeType.toUpperCase()} ${h.amount} ${h.unit}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          h.note?.isNotEmpty == true
                                              ? h.note!
                                              : "No description provided",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Date (right-aligned)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
