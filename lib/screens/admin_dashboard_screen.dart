import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/screens/manage_colleges_screen.dart';
import 'package:supreme_institution/screens/manage_inspection_screen.dart';
import 'package:supreme_institution/screens/manage_tickets_screen.dart';
import 'package:supreme_institution/screens/admin_equipments_not_working_screen.dart';
import 'package:supreme_institution/screens/admin_add_equipment_screen.dart';
import 'package:supreme_institution/screens/admin_mass_stickers_screen.dart';
import 'package:supreme_institution/services/auth_service.dart';
import 'package:supreme_institution/widgets/admin_home_tab.dart';
import 'package:supreme_institution/services/notification_service.dart';
import 'package:supreme_institution/widgets/notification_bell.dart';
import 'package:supreme_institution/widgets/offline_banner.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  @override
  void initState() {
    super.initState();
    // Start listening for notifications (handled by provider/service)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .startListening('admin');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            const NotificationBell(targetUserId: 'admin'),
            IconButton(
              icon: const Icon(Icons.update),
              tooltip: 'Check for Updates',
              onPressed: () async {
                // Ask for confirmation before sending the notification
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Send Update Notification?'),
                    content: const Text('Shall I send update notification?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false), // User pressed No
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true), // User pressed Yes
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );

                // Proceed only if the user confirmed
                if (confirm == true) {
                  // Send update notification only if on Android
                  if (Theme.of(context).platform == TargetPlatform.android) {
                    // Play Store URL for the app
                    const String playStoreUrl = 'market://details?id=com.ram.qrmed'; // Replace with your actual package name
                    
                    await NotificationService.showSystemNotification(
                      id: DateTime.now().millisecond, // Unique ID for notification
                      title: 'Update Available',
                      body: 'A new version of QR Med is available. Tap to update.',
                      payload: playStoreUrl, // Pass URL in payload
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update notification sent to Android users.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update check is only available on Android.')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut(context);
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.school), text: 'Colleges'),
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Add Equipment'),
              Tab(icon: Icon(Icons.folder_zip_outlined), text: 'Mass Stickers'),
              Tab(icon: Icon(Icons.fact_check), text: 'Inspection'),
              Tab(icon: Icon(Icons.confirmation_number), text: 'Tickets'),
              Tab(icon: Icon(Icons.error_outline), text: 'Equipments Not Working'),
            ],
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            const Expanded(
              child: TabBarView(
                children: [
                  AdminHomeTab(),
                  ManageCollegesScreen(),
                  AdminAddEquipmentScreen(),
                  AdminMassStickersScreen(),
                  ManageInspectionScreen(),
                  ManageTicketsScreen(userId: 'admin', userRole: 'admin', collegeId: ''),
                  AdminEquipmentsNotWorkingScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
