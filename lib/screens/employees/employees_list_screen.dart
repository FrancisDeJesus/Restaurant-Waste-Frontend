// lib/screens/employees/employees_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employees/employees_model.dart';
import '../../services/api/employees_api.dart';
import 'employees_form_screen.dart';
import 'employees_detail_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  bool _loading = true;
  String? _error;
  List<Employees> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await EmployeesApi.getAll();
      data.sort((a, b) {
        final da = a.dateHired ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.dateHired ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      setState(() => _employees = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteEmployee(Employees e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${e.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => Navigator.pop(context, true),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await EmployeesApi.delete(e.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully!')),
      );
      await _loadEmployees();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err')),
      );
    }
  }

  void _openForm({Employees? employee}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeesFormScreen(employee: employee),
      ),
    );
    if (changed == true) _loadEmployees();
  }

  String _formatHired(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : _employees.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No employees yet. Tap + to add.')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _employees.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) {
                          final e = _employees[i];
                          final hiredLine = e.dateHired != null
                              ? '\nDate Hired: ${_formatHired(e.dateHired)}'
                              : '';
                          return ListTile(
                            title: Text(e.name),
                            subtitle: Text(
                              '${e.position} • ${e.email.isEmpty ? 'No Email' : e.email}$hiredLine',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _openForm(employee: e),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: e.id == null ? null : () => _deleteEmployee(e),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployeeDetailScreen(employee: e),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
