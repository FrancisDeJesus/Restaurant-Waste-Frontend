class Employees {
  final int? id;
  final String name;
  final String position;
  final String contactNumber;
  final String email;
  final DateTime? dateHired;

  Employees({
    this.id,
    required this.name,
    required this.position,
    required this.contactNumber,
    required this.email,
    this.dateHired,
  });

  factory Employees.fromJson(Map<String, dynamic> json) {
    return Employees(
      id: json['id'],
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      email: json['email'] ?? '',
      dateHired: json['date_hired'] != null
          ? DateTime.parse(json['date_hired'])
          : null, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'contact_number': contactNumber,
      'email': email,
    };
  }
}