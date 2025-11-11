import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employees/employees_model.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employees employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: green),
        title: const Text(
          'EMPLOYEE DETAILS',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 🧑‍💼 Profile Header Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: green.withOpacity(0.15)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: green.withOpacity(0.2),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    employee.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.position,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (employee.dateHired != null)
                    Text(
                      'Hired: ${dateFormat.format(employee.dateHired!)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📋 Information Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: green.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Employee Information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                    icon: Icons.phone,
                    label: "Contact Number",
                    value: employee.contactNumber.isEmpty
                        ? "N/A"
                        : employee.contactNumber,
                  ),
                  const Divider(),
                  _infoRow(
                    icon: Icons.email_outlined,
                    label: "Email",
                    value: employee.email.isEmpty ? "N/A" : employee.email,
                  ),
                  const Divider(),
                  _infoRow(
                    icon: Icons.work_outline,
                    label: "Position",
                    value: employee.position,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 💬 Footer quote or message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "“Dedicated employees are the backbone of sustainable success.”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: green,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    const green = Color(0xFF015704);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
