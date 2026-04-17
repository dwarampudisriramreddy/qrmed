class InspectionResult {
  final bool passed;
  final List<String> missingEquipment;
  final List<String> missingStaff;
  final List<String> excessEquipment;
  final List<String> excessStaff;
  final List<String> notes;

  InspectionResult({
    required this.passed,
    required this.missingEquipment,
    required this.missingStaff,
    required this.excessEquipment,
    required this.excessStaff,
    required this.notes,
  });

  factory InspectionResult.fromJson(Map<String, dynamic> json) {
    return InspectionResult(
      passed: json['passed'] as bool,
      missingEquipment: List<String>.from(json['missingEquipment']),
      missingStaff: List<String>.from(json['missingStaff']),
      excessEquipment: List<String>.from(json['excessEquipment']),
      excessStaff: List<String>.from(json['excessStaff']),
      notes: List<String>.from(json['notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passed': passed,
      'missingEquipment': missingEquipment,
      'missingStaff': missingStaff,
      'excessEquipment': excessEquipment,
      'excessStaff': excessStaff,
      'notes': notes,
    };
  }
}
