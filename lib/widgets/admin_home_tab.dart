import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/inspection_result.dart'; // Import InspectionResult
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart'; // Import InspectionProvider
import 'package:supreme_institution/providers/requirements_provider.dart'; // Import RequirementsProvider
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/widgets/dashboard_tile.dart';
import 'package:supreme_institution/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  College? _selectedCollege;
  String? _selectedDepartment;

  bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    _initializeAppProviders(); // Renamed to a more general initialization
  }

  Future<void> _initializeAppProviders() async {
    // Access providers with listen: false here, as we are in initState
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);

    // Initialize system notification listening
    notificationProvider.startListening('admin');

    // Fetch all necessary data in parallel
    await Future.wait([
      collegeProvider.fetchColleges(),
      equipmentProvider.fetchEquipments(),
      departmentProvider.fetchDepartments(), 
      employeeProvider.fetchEmployees(),
      ticketProvider.fetchTickets(),
      requirementsProvider.fetchRequirements(),
    ]);

    // After all data is fetched, set initial college and trigger a rebuild
    if (mounted) {
      setState(() {
        if (collegeProvider.colleges.isNotEmpty) {
          _selectedCollege = collegeProvider.colleges.first;
        }
        _isLoading = false; // Data is loaded
      });
    }
  }

  void _showInspectionResultDialog(InspectionResult result) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            result.passed ? 'Inspection Passed!' : 'Inspection Failed!',
            style: TextStyle(color: result.passed ? Colors.green : Colors.red),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Overall Status: ${result.passed ? 'PASS' : 'FAIL'}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: result.passed ? Colors.green : Colors.red),
                  ),
                ),
                if (result.missingEquipment.isNotEmpty) ...[
                  _buildInspectionSection(
                    title: 'Missing Equipment',
                    items: result.missingEquipment,
                    icon: Icons.inventory_2_outlined,
                    itemColor: Colors.orange,
                  ),
                ],
                if (result.missingStaff.isNotEmpty) ...[
                  _buildInspectionSection(
                    title: 'Missing Staff',
                    items: result.missingStaff,
                    icon: Icons.person_off_outlined,
                    itemColor: Colors.orange,
                  ),
                ],
                if (result.excessEquipment.isNotEmpty) ...[
                  _buildInspectionSection(
                    title: 'Excess Equipment',
                    items: result.excessEquipment,
                    icon: Icons.inventory_2,
                    itemColor: Colors.redAccent,
                  ),
                ],
                if (result.excessStaff.isNotEmpty) ...[
                  _buildInspectionSection(
                    title: 'Excess Staff',
                    items: result.excessStaff,
                    icon: Icons.people_alt_outlined,
                    itemColor: Colors.redAccent,
                  ),
                ],
                if (result.notes.isNotEmpty) ...[
                  _buildInspectionSection(
                    title: 'Notes',
                    items: result.notes,
                    icon: Icons.note_add_outlined,
                    itemColor: Colors.blueGrey,
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInspectionSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color itemColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: itemColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: itemColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Text('- $item', style: const TextStyle(fontSize: 14)),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final collegeProvider = Provider.of<CollegeProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context); // Added
    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);

    final collegeCount = collegeProvider.colleges.length;
    final departmentCount = departmentProvider.departments.length; // Added
    final employeeCount = employeeProvider.employees.length;       // Added
    final ticketCount = ticketProvider.tickets.length;
    
    // Use the same filtering logic as the dedicated tab for consistency
    final notWorkingEquipmentCount = equipmentProvider.equipments
        .where((e) => e.isNotWorking)
        .length;
    
    final departments = _selectedCollege != null
        ? departmentProvider.getDepartmentsForCollege(_selectedCollege!.id)
        : <Department>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveUtils.getMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: ResponsiveUtils.getCrossAxisCount(context),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: ResponsiveUtils.getChildAspectRatio(context),
                children: [
                  DashboardTile(
                    count: collegeCount.toString(),
                    title: 'Total Colleges',
                    icon: Icons.school,
                    color: Colors.blue,
                    onTap: () => DefaultTabController.of(context).animateTo(1),
                  ),
              DashboardTile(
                count: departmentCount.toString(), // Added
                title: 'Total Departments',          // Added
                icon: Icons.business,                 // Added
                color: Colors.green,                  // Added
              ),
              DashboardTile(
                count: employeeCount.toString(),       // Added
                title: 'Total Employees',              // Added
                icon: Icons.people,                   // Added
                color: Colors.purple,                 // Added
              ),
              DashboardTile(
                count: ticketCount.toString(),
                title: 'Total Tickets',
                icon: Icons.confirmation_number,
                color: Colors.orange,
                onTap: () => DefaultTabController.of(context).animateTo(5),
              ),
              DashboardTile(
                count: notWorkingEquipmentCount.toString(),
                title: 'Equipments Not Working',
                icon: Icons.build_circle,
                color: Colors.red,
                onTap: () => DefaultTabController.of(context).animateTo(6),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('College Inspection Verification', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          collegeProvider.colleges.isEmpty
              ? const Text('No colleges available for inspection.')
              : Column(
                  children: [
                    DropdownButtonFormField<College>(
                      isExpanded: true,
                      initialValue: _selectedCollege,
                      decoration: const InputDecoration(
                        labelText: 'Select College',
                        border: OutlineInputBorder(),
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return collegeProvider.colleges.map((college) {
                          return Text(
                            college.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }).toList();
                      },
                      items: collegeProvider.colleges
                          .map((college) => DropdownMenuItem(
                                value: college,
                                child: Text(
                                  college.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                      onChanged: (College? newValue) {
                        setState(() {
                          _selectedCollege = newValue;
                          _selectedDepartment = null;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a college';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedCollege != null)
                      Builder(
                        builder: (context) {
                          // Get unique department names to avoid "Duplicate value" error in Dropdown
                          final uniqueDeptNames = departments.map((d) => d.name).toSet().toList()..sort();
                          
                          // Ensure _selectedDepartment is valid
                          if (_selectedDepartment != null && _selectedDepartment != 'All' && !uniqueDeptNames.contains(_selectedDepartment)) {
                            // If it's invalid, we could either reset to null or 'All'
                            // or temporarily add it to the list to avoid crash.
                            // Adding it to the list is safer for preserving state.
                            uniqueDeptNames.add(_selectedDepartment!);
                          }

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedDepartment,
                            decoration: const InputDecoration(
                              labelText: 'Select Department',
                              border: OutlineInputBorder(),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return [
                                const Text('All', overflow: TextOverflow.ellipsis, maxLines: 1),
                                ...uniqueDeptNames.map((String name) {
                                  return Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                }),
                              ];
                            },
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'All',
                                child: Text('All', overflow: TextOverflow.ellipsis, maxLines: 1),
                              ),
                              ...uniqueDeptNames.map((String name) {
                                return DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedDepartment = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a department';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _selectedCollege == null
                          ? null
                          : () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Performing inspection...')),
                              );

                              final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);
                              final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
                              
                              final result = await inspectionProvider.performInspectionForCollege(
                                college: _selectedCollege!,
                                dynamicRequirements: requirementsProvider.requirements,
                              );

                              _showInspectionResultDialog(result);
                            },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Perform Inspection Verification'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _launchUrl('https://dciindia.gov.in/InspetionProfomas.aspx'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Check DCI Inspection Proformas',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }
}