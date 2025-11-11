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
        const SnackBar(content: Text('✅ Employee saved successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
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
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: green),
        centerTitle: true,
        title: Text(
          widget.employee == null ? 'ADD EMPLOYEE' : 'EDIT EMPLOYEE',
          style: const TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🖼️ Header Image
            Center(
              child: Image.asset(
                'assets/add_employee.png', // ✅ Make sure this path is correct
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.employee == null
                  ? 'Register a New Employee'
                  : 'Update Employee Information',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // 🧾 Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _name,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _name = v!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _position,
                      decoration:
                          _inputDecoration('Position', Icons.work_outline),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _position = v!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _contactNumber,
                      decoration: _inputDecoration(
                          'Contact Number', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _contactNumber = v!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _email,
                      decoration:
                          _inputDecoration('Email', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : (!v.contains('@')
                              ? 'Invalid email'
                              : null),
                      onSaved: (v) => _email = v!.trim(),
                    ),
                    const SizedBox(height: 28),

                    // 💾 Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _saving ? 'Saving...' : 'Save Employee',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    const green = Color(0xFF015704);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 1.6),
      ),
    );
  }
}
