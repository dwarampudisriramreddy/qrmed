import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/app_notification.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/screens/manage_employees_screen.dart';
import 'package:supreme_institution/screens/manage_inspection_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/screens/manage_equipments_screen.dart';
import 'package:supreme_institution/screens/manage_departments_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/college_home_tab.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';
import 'package:supreme_institution/widgets/offline_banner.dart';
import 'package:supreme_institution/services/notification_service.dart';

class CollegeDashboardScreen extends StatefulWidget {
  final College college;

  const CollegeDashboardScreen({super.key, required this.college});

  @override
  State<CollegeDashboardScreen> createState() => _CollegeDashboardScreenState();
}

class _CollegeDashboardScreenState extends State<CollegeDashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  late final College _currentCollege;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _currentCollege = widget.college;
    _widgetOptions = <Widget>[
      CollegeHomeTab(
        college: _currentCollege,
        onTabSelected: _onItemTapped,
      ),
      ManageEquipmentsScreen(collegeName: _currentCollege.id),
      ManageEmployeesScreen(
        collegeId: _currentCollege.id,
        collegeType: _currentCollege.type,
      ),
      ManageDepartmentsScreen(college: _currentCollege),
      ManageTicketsScreen(
        userId: _currentCollege.id,
        userRole: 'college',
        collegeId: _currentCollege.id,
        collegeName: _currentCollege.name,
      ),
    ];

    // Listen for real-time notifications (handled by provider/service)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.startListening(_currentCollege.id);
      
      // Request permission for local notifications
      if (NotificationService.isSystemNotificationSupported) {
        await NotificationService.requestPermission();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _widgetOptions[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Depts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
        ],
      ),
      floatingActionButton: null,
      appBar: AppBar(
        title: Text(_currentCollege.name),
        actions: [
          NotificationBell(targetUserId: _currentCollege.id),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut(context);
            },
          ),
        ],
      ),
    );
  }
}
