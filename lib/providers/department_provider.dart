import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supreme_institution/models/department.dart';

class DepartmentProvider with ChangeNotifier {
  final CollectionReference _departmentCollection =
      FirebaseFirestore.instance.collection('departments');

  List<Department> _departments = [];

  List<Department> get departments => _departments;

  List<Department> getDepartmentsForCollege(String collegeId) {
    return _departments.where((dep) => dep.collegeId == collegeId).toList();
  }

  Future<void> fetchDepartments() async {
    try {
      final snapshot = await _departmentCollection.get();
      _departments = snapshot.docs
          .map((doc) => Department.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching departments: $e');
    }
  }

  Future<void> fetchDepartmentsForCollege(String collegeId) async {
    try {
      final snapshot = await _departmentCollection
          .where('collegeId', isEqualTo: collegeId)
          .get();
      _departments = snapshot.docs
          .map((doc) => Department.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching departments for college: $e');
    }
  }

  Future<void> addDepartment(Department department) async {
    try {
      await _departmentCollection.doc(department.id).set(department.toJson());
      await fetchDepartmentsForCollege(department.collegeId);
    } catch (e) {
      print('Error adding department: $e');
    }
  }

  Future<void> deleteDepartment(String departmentId, String collegeId) async {
    try {
      await _departmentCollection.doc(departmentId).delete();
      await fetchDepartmentsForCollege(collegeId);
    } catch (e) {
      print('Error deleting department: $e');
    }
  }

  Future<void> updateDepartment(Department department) async {
    try {
      await _departmentCollection
          .doc(department.id)
          .update(department.toJson());
      await fetchDepartmentsForCollege(department.collegeId);
    } catch (e) {
      print('Error updating department: $e');
    }
  }
}
