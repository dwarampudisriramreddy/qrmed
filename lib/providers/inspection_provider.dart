import 'package:flutter/material.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/models/inspection_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionProvider with ChangeNotifier {
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');
  final CollectionReference _employeeCollection =
      FirebaseFirestore.instance.collection('employees');

  Future<List<Equipment>> _fetchCollegeEquipments(String collegeId) async {
    final snapshot = await _equipmentCollection.where('collegeId', isEqualTo: collegeId).get();
    return snapshot.docs
        .map((doc) => Equipment.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Employee>> _fetchCollegeEmployees(String collegeId) async {
    final snapshot = await _employeeCollection.where('collegeId', isEqualTo: collegeId).get();
    return snapshot.docs
        .map((doc) => Employee.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<InspectionResult> performInspectionForCollege({
    required College college,
    Department? department,
    Map<String, Map<String, Map<String, Map<String, dynamic>>>>? dynamicRequirements,
  }) async {
    final collegeEquipments = await _fetchCollegeEquipments(college.id);
    final collegeEmployees = await _fetchCollegeEmployees(college.id);
    return _performInspection(
      college: college,
      collegeEquipments: collegeEquipments,
      collegeEmployees: collegeEmployees,
      department: department,
      dynamicRequirements: dynamicRequirements,
    );
  }

  InspectionResult _performInspection({
    required College college,
    required List<Equipment> collegeEquipments,
    required List<Employee> collegeEmployees,
    Department? department,
    Map<String, Map<String, Map<String, Map<String, dynamic>>>>? dynamicRequirements,
  }) {
    print('Performing inspection for college: ${college.name}');
    print('College type: ${college.type}, Seats: ${college.seats}');
    print('Number of equipments in college: ${collegeEquipments.length}');
    print('Number of employees in college: ${collegeEmployees.length}');

    final List<String> missingEquipment = [];
    final List<String> missingStaff = [];
    final List<String> excessEquipment = [];
    final List<String> excessStaff = [];
    final List<String> notes = [];

    String collegeType = college.type.toUpperCase();
    if (collegeType == 'DENTAL') {
      collegeType = 'BDS';
    } else if (collegeType == 'MEDICAL') {
      collegeType = 'MBBS';
    }
    final seats = college.seats.toString(); // Use string representation for keys

    // Use dynamic requirements if provided
    final activeRequirements = dynamicRequirements;

    bool requirementsFound = false;
    if (activeRequirements != null && 
        activeRequirements.containsKey(collegeType) && 
        activeRequirements[collegeType]!.containsKey(seats)) {
      final departmentRequirements = activeRequirements[collegeType]![seats]!;
      print('Found requirements for $collegeType with $seats seats.');
      requirementsFound = true;

      final departmentsToInspect = department != null
          ? {department.name: departmentRequirements[department.name]}
          : departmentRequirements;

      if (department != null && !departmentRequirements.containsKey(department.name)) {
        notes.add('No requirements found for department: ${department.name}');
        requirementsFound = false;
      } else {
        departmentsToInspect.forEach((departmentName, reqs) {
          if (reqs == null) return;
          final requiredEquipments = Map<String, int>.from(reqs['equipments'] ?? {});
          final requiredEmployees = Map<String, int>.from(reqs['employees'] ?? {});

          // Check equipment
          requiredEquipments.forEach((equipmentName, requiredCount) {
            final actualCount = collegeEquipments
                .where((e) {
                    String eDept = e.department.trim().toLowerCase();
                    // Strip any (...) suffix if present
                    if (eDept.contains('(') && eDept.endsWith(')')) {
                      eDept = eDept.substring(0, eDept.lastIndexOf('(')).trim();
                    }
                    return eDept == departmentName.toLowerCase() &&
                           e.name.trim().toLowerCase() == equipmentName.toLowerCase();
                })
                .length;
            if (actualCount < requiredCount) {
              missingEquipment.add('$departmentName: $equipmentName: ${requiredCount - actualCount} missing');
            } else if (actualCount > requiredCount) {
              excessEquipment.add('$departmentName: $equipmentName: ${actualCount - requiredCount} excess');
            }
          });

          // Check employees
          requiredEmployees.forEach((role, requiredCount) {
            final actualCount = collegeEmployees
                .where((emp) {
                    if (emp.department == null) return false;
                    String empDept = emp.department!.trim().toLowerCase();
                    // Strip any (...) suffix if present
                    if (empDept.contains('(') && empDept.endsWith(')')) {
                      empDept = empDept.substring(0, empDept.lastIndexOf('(')).trim();
                    }
                    return empDept == departmentName.toLowerCase() &&
                           emp.role != null &&
                           emp.role!.trim().toLowerCase() == role.toLowerCase();
                })
                .length;
            if (actualCount < requiredCount) {
              missingStaff.add('$departmentName: $role: ${requiredCount - actualCount} missing');
            } else if (actualCount > requiredCount) {
              excessStaff.add('$departmentName: $role: ${actualCount - requiredCount} excess');
            }
          });
        });
      }
    } else {
      notes.add('No requirements found in Firestore for ${college.type} with ${college.seats} seats.');
      print('No requirements found for $collegeType with $seats seats.');
    }

    final bool passed = requirementsFound && missingEquipment.isEmpty && missingStaff.isEmpty;
    print('Inspection passed: $passed');
    print('Missing equipment: $missingEquipment');
    print('Missing staff: $missingStaff');

    return InspectionResult(
      passed: passed,
      missingEquipment: missingEquipment,
      missingStaff: missingStaff,
      excessEquipment: excessEquipment,
      excessStaff: excessStaff,
      notes: notes,
    );
  }
}