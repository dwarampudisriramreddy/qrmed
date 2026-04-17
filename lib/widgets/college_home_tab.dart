import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/models/inspection_result.dart'; // Import InspectionResult
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart';
import 'package:supreme_institution/providers/requirements_provider.dart';
import 'package:supreme_institution/widgets/dashboard_tile.dart';
import 'package:supreme_institution/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CollegeHomeTab extends StatefulWidget {
  final College college;
  final Function(int)? onTabSelected;

  const CollegeHomeTab({super.key, required this.college, this.onTabSelected});

  @override
  State<CollegeHomeTab> createState() => _CollegeHomeTabState();
}

class _CollegeHomeTabState extends State<CollegeHomeTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAppProviders();
  }

  Future<void> _initializeAppProviders() async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false); 
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Initialize system notification listening
    notificationProvider.startListening(widget.college.id);

    await Future.wait([
      employeeProvider.fetchEmployees(),
      equipmentProvider.fetchEquipments(),
      departmentProvider.fetchDepartments(),
      requirementsProvider.fetchRequirements(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInspectionResultDialog(InspectionResult result) { // Renamed from showInspectionResultDialog to _show...
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            result.passed ? 'Inspection Passed!' : 'Inspection Failed!',
            style: TextStyle(color: result.passed ? Colors.green : Colors.red),
          ),
          content: SingleChildScrollView(
            child: Column( // Changed from ListBody
              mainAxisSize: MainAxisSize.min, // Added
              crossAxisAlignment: CrossAxisAlignment.start, // Added
              children: [
                Padding( // Added
                  padding: const EdgeInsets.only(bottom: 8.0), // Added
                  child: Text( // Added
                    'Overall Status: ${result.passed ? 'PASS' : 'FAIL'}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: result.passed ? Colors.green : Colors.red),
                  ),
                ),
                if (result.missingEquipment.isNotEmpty) ...[
                  _buildInspectionSection( // Changed to private helper method
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

  Widget _buildInspectionSection({ // New helper method
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

  void _showDepartmentSelectionDialog() { // Renamed from showDepartmentSelectionDialog to _show...
    Department? selectedDepartment;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
            return AlertDialog(
              title: const Text('Select Department'),
              content: DropdownButtonFormField<Department>(
                isExpanded: true,
                initialValue: selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department'),
                selectedItemBuilder: (BuildContext context) {
                  return departmentProvider.getDepartmentsForCollege(widget.college.id).map((department) {
                    final displayName = department.subSelectionType != null 
                        ? "${department.name} (${department.subSelectionType})"
                        : department.name;
                    return Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: departmentProvider.getDepartmentsForCollege(widget.college.id).map((department) {
                  final displayName = department.subSelectionType != null 
                      ? "${department.name} (${department.subSelectionType})"
                      : department.name;
                  return DropdownMenuItem<Department>(
                    value: department,
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (department) {
                  setState(() {
                    selectedDepartment = department;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Inspect'),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Performing inspection...')),
                    );

                    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);
                    final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
                    final result = await inspectionProvider.performInspectionForCollege(
                      college: widget.college,
                      department: selectedDepartment,
                      dynamicRequirements: requirementsProvider.requirements,
                    );

                    _showInspectionResultDialog(result); // Called private method
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fetching providers to get data
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false); // Still listen: false if not rebuilding on inspection changes
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    // Filtering data based on collegeId (normalize to handle whitespace)
    final collegeEquipments = equipmentProvider.equipments
        .where((e) => e.collegeId.trim() == widget.college.id.trim())
        .toList();
    final totalEquipments = collegeEquipments.length;
    
    final totalEmployees = employeeProvider.employees.where((e) => e.collegeId.trim() == widget.college.id.trim()).length;
    final totalDepartments = departmentProvider.getDepartmentsForCollege(widget.college.id).length;
    final notWorkingEquipments = collegeEquipments
        .where((e) => e.isNotWorking)
        .length;

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
                    count: totalEquipments.toString(),
                    title: 'Total Equipments',
                    icon: Icons.devices_other,
                    color: Colors.green,
                    onTap: () => widget.onTabSelected?.call(1),
                  ),
              DashboardTile(
                count: totalDepartments.toString(),
                title: 'Total Departments',
                icon: Icons.business,
                color: Colors.purple,
                onTap: () => widget.onTabSelected?.call(3),
              ),
              DashboardTile(
                count: totalEmployees.toString(),
                title: 'Total Employees',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => widget.onTabSelected?.call(2),
              ),
              DashboardTile(
                count: notWorkingEquipments.toString(),
                title: 'Equipments Not Working',
                icon: Icons.build,
                color: Colors.red,
                onTap: () => widget.onTabSelected?.call(1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Department Inspection Verification', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _showDepartmentSelectionDialog(); // Called private method
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