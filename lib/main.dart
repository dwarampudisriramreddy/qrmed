import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase.initializeApp
import 'package:supreme_institution/firebase_options.dart'; // Required for DefaultFirebaseOptions
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/manage_colleges_screen.dart';
import 'screens/add_edit_college_screen.dart';
import 'screens/manage_inspection_screen.dart';
import 'screens/employee_dashboard_screen.dart';
import 'screens/college_dashboard_screen.dart';
import 'models/college.dart';
import 'providers/college_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/product_provider.dart';
import 'providers/equipment_provider.dart'; // Import EquipmentProvider
import 'providers/inspection_provider.dart'; // Import InspectionProvider
import 'providers/requirements_provider.dart'; // Import RequirementsProvider
import 'package:supreme_institution/providers/department_provider.dart'; // Import DepartmentProvider
import 'package:supreme_institution/providers/ticket_provider.dart'; // Import TicketProvider
import 'package:supreme_institution/providers/notification_provider.dart'; // Import NotificationProvider
import 'package:supreme_institution/providers/connectivity_provider.dart'; // Import ConnectivityProvider
import 'package:supreme_institution/services/auth_service.dart'; // Import AuthService
import 'package:supreme_institution/services/auth_storage_service.dart'; // Import AuthStorageService
import 'package:supreme_institution/services/notification_service.dart'; // Import NotificationService
import 'widgets/app_loading_widget.dart'; // Import AppLoadingWidget
import 'package:flutter_native_splash/flutter_native_splash.dart';

void testFirestore() async {
  try {
    await FirebaseFirestore.instance
        .collection('test')
        .add({'time': DateTime.now().toString(), 'packageName': 'com.ram.qrmed'});

    print("✅ Firestore WRITE SUCCESS");
  } catch (e) {
    print("❌ Firestore ERROR: $e");
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CollegeProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()), // Add EquipmentProvider
        ChangeNotifierProvider(create: (_) => InspectionProvider()), // Add InspectionProvider
        ChangeNotifierProvider(create: (_) => RequirementsProvider()), // Add RequirementsProvider
        ChangeNotifierProvider(create: (_) => DepartmentProvider()), // Add DepartmentProvider
        ChangeNotifierProvider(create: (_) => TicketProvider()), // Add TicketProvider
        ChangeNotifierProvider(create: (_) => NotificationProvider()), // Add NotificationProvider
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()), // Add ConnectivityProvider
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: Builder(builder: (context) {
        return MaterialApp(
          title: 'QR Med',
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          themeMode: ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1F2937),
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          routes: {
            '/admin': (context) => const AdminDashboardScreen(),
            '/manageColleges': (context) => const ManageCollegesScreen(),
            '/manageInspection': (context) => const ManageInspectionScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/addEditCollege') {
              final college = settings.arguments as dynamic;
              return MaterialPageRoute(
                builder: (context) => AddEditCollegeScreen(college: college is College ? college : null),
              );
            }
            if (settings.name == '/employeeDashboard') {
              final args = settings.arguments as Map<String, String>? ?? {};
              final employeeId = args['employeeId'] ?? '';
              final collegeName = args['collegeName'] ?? 'College';
              return MaterialPageRoute(
                builder: (context) => EmployeeDashboardScreen(employeeId: employeeId, collegeName: collegeName),
              );
            }
            if (settings.name == '/collegeDashboard') {
              final collegeId = settings.arguments as String? ?? '';
              final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
                              final college = collegeProvider.colleges.firstWhere(
                              (c) => c.id == collegeId,
                              orElse: () => College(id: 'not-found', collegeCode: '', name: 'Error', city: '', type: '', seats: '', password: ''),
                            );              if (college.id == 'not-found') {
                return MaterialPageRoute(builder: (_) => const AppLoadingWidget(message: 'College not found'));
              }
              return MaterialPageRoute(
                builder: (context) => CollegeDashboardScreen(college: college),
              );
            }
            return null;
          },
        );
      }),
    );
  }
}

// Wrapper widget to check for saved login credentials
class AuthWrapper extends StatefulWidget {
  final String initialMessage;
  const AuthWrapper({super.key, this.initialMessage = "Initializing..."});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  Widget _initialRoute = const LoginScreen();

  @override
  void initState() {
    super.initState();
    testFirestore();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    // Ensure splash screen is visible for at least 2 seconds
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _performAuthCheck(),
    ]);
    
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _performAuthCheck() async {
    // First, fetch colleges to ensure data is available
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    await collegeProvider.fetchColleges();
    
    final savedCredentials = await AuthStorageService.getSavedCredentials();
    
    if (savedCredentials != null) {
      final userType = savedCredentials['userType']!;
      
      // Navigate based on user type
      if (userType == 'admin') {
        _initialRoute = const AdminDashboardScreen();
      } else if (userType == 'college') {
        final collegeId = savedCredentials['collegeId'] ?? '';
        try {
          final college = collegeProvider.colleges.firstWhere(
            (c) => c.id == collegeId,
          );
          _initialRoute = CollegeDashboardScreen(college: college);
        } catch (_) {
          // College not found, return to login
          _initialRoute = const LoginScreen();
        }
      } else if (userType == 'employee') {
        final employeeId = savedCredentials['email']!;
        final collegeName = savedCredentials['collegeName'] ?? 'College';
        _initialRoute = EmployeeDashboardScreen(
          employeeId: employeeId,
          collegeName: collegeName,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return AppLoadingWidget(message: widget.initialMessage);
    }
    
    return _initialRoute;
  }
}
