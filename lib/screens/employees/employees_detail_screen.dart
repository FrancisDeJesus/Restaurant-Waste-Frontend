// lib/screens/employees/employee_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employees/employees_model.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employees employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Position: ${employee.position}'),
                Text('Contact: ${employee.contactNumber.isEmpty ? "N/A" : employee.contactNumber}'),
                Text('Email: ${employee.email.isEmpty ? "N/A" : employee.email}'),
                const SizedBox(height: 12),
                if (employee.dateHired != null)
                  Text(
                    'Date Hired: ${dateFormat.format(employee.dateHired!)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
