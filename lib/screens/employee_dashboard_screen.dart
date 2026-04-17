import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/find_equipment_widget.dart';
import 'package:supreme_institution/widgets/my_equipments_widget.dart';
import 'package:supreme_institution/widgets/college_equipments_widget.dart';
import 'package:supreme_institution/widgets/employee_home_tab.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';
import 'package:supreme_institution/widgets/offline_banner.dart';
import 'package:supreme_institution/services/notification_service.dart';
import 'package:supreme_institution/models/app_notification.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final String employeeId;
  final String collegeName;

  const EmployeeDashboardScreen({
    super.key,
    required this.employeeId,
    required this.collegeName,
  });

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {

  @override
  void initState() {
    super.initState();
    // Start listening for notifications (handled by provider/service)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .startListening(widget.employeeId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.employeeId),
          actions: [
            NotificationBell(targetUserId: widget.employeeId),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut(context);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.home), text: 'Home'),
              const Tab(icon: Icon(Icons.search), text: 'Find Out'),
              const Tab(icon: Icon(Icons.person_pin_circle_outlined), text: 'My Equipments'),
              Tab(icon: const Icon(Icons.school), text: '${widget.collegeName} Equipments'),
            ],
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: FutureBuilder<Employee?>(
                future: employeeProvider.getEmployeeById(widget.employeeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('Error: Employee not found.'));
                  }
                  final employee = snapshot.data!;

                  return FutureBuilder<void>(
                    future: equipmentProvider.fetchEquipments(),
                    builder: (context, equipmentSnapshot) {
                      if (equipmentSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return TabBarView(
                        children: [
                          EmployeeHomeTab(
                            collegeName: employee.collegeId, 
                            employeeId: widget.employeeId,
                            employeeRole: employee.role,
                            employeeDepartment: employee.department,
                          ),
                          FindEquipmentWidget(currentEmployeeId: widget.employeeId),
                          MyEquipmentsWidget(
                            employeeId: widget.employeeId, 
                            collegeName: employee.collegeId,
                            employeeRole: employee.role,
                            employeeDepartment: employee.department,
                          ),
                          CollegeEquipmentsWidget(collegeName: employee.collegeId),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
