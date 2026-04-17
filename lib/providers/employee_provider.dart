
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  final CollectionReference _employeeCollection =
      FirebaseFirestore.instance.collection('employees');

  List<Employee> _employees = [];
  List<Employee> get employees => _employees;

  Future<void> fetchEmployees() async {
    final snapshot = await _employeeCollection.get();
    _employees = snapshot.docs
        .map((doc) => Employee.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<Employee?> getEmployeeById(String employeeId) async {
    final doc = await _employeeCollection.doc(employeeId).get();
    if (doc.exists) {
      return Employee.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> addEmployee(Employee employee) async {
    await _employeeCollection.doc(employee.id).set(employee.toJson());
    await fetchEmployees();
  }

  Future<void> updateEmployee(String id, Employee employee) async {
    await _employeeCollection.doc(id).update(employee.toJson());
    await fetchEmployees();
  }

  Future<void> assignEquipmentToEmployee(String employeeId, String equipmentId) async {
    final employee = await getEmployeeById(employeeId);
    if (employee != null) {
      if (!employee.assignedEquipments.contains(equipmentId)) {
        employee.assignedEquipments.add(equipmentId);
        await updateEmployee(employeeId, employee);
      }
    }
  }

  Future<void> removeEquipmentFromEmployee(String employeeId, String equipmentId) async {
    final employee = await getEmployeeById(employeeId);
    if (employee != null) {
      if (employee.assignedEquipments.contains(equipmentId)) {
        employee.assignedEquipments.remove(equipmentId);
        await updateEmployee(employeeId, employee);
      }
    }
  }

  Future<void> deleteEmployee(String id) async {
    await _employeeCollection.doc(id).delete();
    await fetchEmployees();
  }
}
