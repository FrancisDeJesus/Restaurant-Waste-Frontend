// lib/services/api/employees_api.dart
import 'dart:convert';
import '../../models/employees/employees_model.dart';
import '../api_service.dart'; // ✅ use your central API handler

class EmployeesApi {
  static const String _path = "employees/";

  // ---------------- ALL EMPLOYEE ------------------------------------------
  
  static Future<List<Employees>> getAll() async {
    final response = await ApiService.get(_path);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Employees.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to fetch employees (${response.statusCode}): ${response.body}');
    }
  }

  // ---------------- CREATE EMPLOYEE ---------------------------------------

  static Future<void> create(Employees employee) async {
    final response =
        await ApiService.post("employees/add/", employee.toJson());
    if (response.statusCode != 201) {
      throw Exception('Failed to create employee: ${response.body}');
    }
  }

  // ---------------- UPDATE EMPLOYEE ---------------------------------------

  static Future<void> update(Employees employee) async {
    if (employee.id == null) throw Exception('Missing employee ID');
    final response = await ApiService.put(
        "employees/${employee.id}/edit/", employee.toJson());
    if (response.statusCode != 200) {
      throw Exception('Failed to update employee: ${response.body}');
    }
  }

  // ---------------- DELETE EMPLOYEE ---------------------------------------

  static Future<void> delete(int id) async {
    final response = await ApiService.delete("employees/$id/delete/");
    if (response.statusCode != 204) {
      throw Exception('Failed to delete employee: ${response.body}');
    }
  }
}
