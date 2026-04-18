import 'package:flutter/material.dart';
import 'package:supreme_institution/screens/my_equipments_screen.dart';

class MyEquipmentsWidget extends StatelessWidget {
  final String employeeId;
  final String collegeName;
  final String? employeeRole;
  final List<String> employeeDepartments;

  const MyEquipmentsWidget({
    super.key, 
    required this.employeeId, 
    required this.collegeName,
    this.employeeRole,
    this.employeeDepartments = const [],
  });

  @override
  Widget build(BuildContext context) {
    // This widget now acts as a wrapper that directly presents the MyEquipmentsScreen logic.
    return MyEquipmentsScreen(
      employeeId: employeeId, 
      collegeName: collegeName,
      employeeRole: employeeRole,
      employeeDepartments: employeeDepartments,
    );
  }
}