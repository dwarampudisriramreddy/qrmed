class Department {
  final String id;
  final String name;
  final String collegeId;
  final String? subSelectionType; // UG or PG

  Department({
    required this.id,
    required this.name,
    required this.collegeId,
    this.subSelectionType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'collegeId': collegeId,
      'subSelectionType': subSelectionType,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'collegeId': collegeId,
      'subSelectionType': subSelectionType,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      collegeId: map['collegeId'] ?? '',
      subSelectionType: map['subSelectionType'],
    );
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      collegeId: json['collegeId'] ?? '',
      subSelectionType: json['subSelectionType'],
    );
  }
}
