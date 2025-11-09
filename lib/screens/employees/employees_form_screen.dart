// lib/screens/employees/employees_form_screen.dart
import 'package:flutter/material.dart';
import '../../models/employees/employees_model.dart';
import '../../services/api/employees_api.dart';

class EmployeesFormScreen extends StatefulWidget {
  final Employees? employee;
  const EmployeesFormScreen({super.key, this.employee});

  @override
  State<EmployeesFormScreen> createState() => _EmployeesFormScreenState();
}

class _EmployeesFormScreenState extends State<EmployeesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _position;
  late String _contactNumber;
  late String _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.employee?.name ?? '';
    _position = widget.employee?.position ?? '';
    _contactNumber = widget.employee?.contactNumber ?? '';
    _email = widget.employee?.email ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);

    try {
      final employee = Employees(
        id: widget.employee?.id,
        name: _name,
        position: _position,
        contactNumber: _contactNumber,
        email: _email,
      
      );

      if (widget.employee == null) {
        await EmployeesApi.create(employee);
      } else {
        await EmployeesApi.update(employee);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee saved successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              TextFormField(
                initialValue: _position,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _position = v!.trim(),
              ),
              TextFormField(
                initialValue: _contactNumber,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _contactNumber = v!.trim(),
              ),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid email' : null),
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
