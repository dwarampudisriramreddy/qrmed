class Employee {
  String id; // employeename@collegename.com
  String name;
  String password;
  String collegeId;
  String? role;
  List<String> departments; // Changed from String? department
  String? email;
  String? phone;
  List<String> assignedEquipments; // New field

  Employee({
    required this.id,
    required this.name,
    required this.password,
    required this.collegeId,
    this.role,
    this.departments = const [], // Initialize as empty list
    this.email,
    this.phone,
    this.assignedEquipments = const [], // Initialize as empty list
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Handle migration from old 'department' field if it exists
    List<String> depts = [];
    if (json['departments'] != null) {
      depts = List<String>.from(json['departments']);
    } else if (json['department'] != null && json['department'].toString().isNotEmpty) {
      depts = [json['department'].toString()];
    }

    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
      collegeId: json['collegeId'] as String,
      role: json['role'] as String?,
      departments: depts,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      assignedEquipments: List<String>.from(json['assignedEquipments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'collegeId': collegeId,
      'role': role,
      'departments': departments,
      'email': email,
      'phone': phone,
      'assignedEquipments': assignedEquipments,
    };
  }

  // Legacy getter for backward compatibility if needed in some places
  String? get department => departments.isNotEmpty ? departments.first : null;
}
