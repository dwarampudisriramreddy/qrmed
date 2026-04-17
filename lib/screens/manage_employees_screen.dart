import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../providers/department_provider.dart';
import '../providers/equipment_provider.dart'; // Added
import 'add_edit_employee_screen.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

class ManageEmployeesScreen extends StatefulWidget {
  final String collegeId;
  final String collegeType; // 'Dental' or 'MBBS'
  const ManageEmployeesScreen({super.key, required this.collegeId, required this.collegeType});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  List<Employee> _employees = [];
  final _searchController = TextEditingController();
  String? _selectedDepartmentFilter; // Added for filter
  String? _selectedRoleFilter; // Added for interactive chip filtering

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    // Fetch departments to ensure they're loaded for validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DepartmentProvider>(context, listen: false)
          .fetchDepartmentsForCollege(widget.collegeId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    await Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
    setState(() {
      _employees = Provider.of<EmployeeProvider>(context, listen: false)
          .employees
          .where((e) => e.collegeId == widget.collegeId)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final departmentsList = departmentProvider.getDepartmentsForCollege(widget.collegeId);
    
    // Ensure unique department names for the filter dropdown
    final uniqueDepartmentNames = departmentsList.map((d) {
      return d.subSelectionType != null ? "${d.name} (${d.subSelectionType})" : d.name;
    }).toSet().toList()..sort();

    final query = _searchController.text.toLowerCase();
    final filteredEmployees = _employees.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(query) ||
          e.id.toLowerCase().contains(query) ||
          (e.email?.toLowerCase().contains(query) ?? false) ||
          (e.role?.toLowerCase().contains(query) ?? false) ||
          (e.department?.toLowerCase().contains(query) ?? false);
      
      final matchesDept = _selectedDepartmentFilter == null || 
          e.department == _selectedDepartmentFilter;
      
      return matchesQuery && matchesDept;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, ID or role...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.green),
                hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 15),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                if (uniqueDepartmentNames.isNotEmpty)
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDepartmentFilter,
                        hint: const Text('All Departments', style: TextStyle(fontSize: 13, color: Colors.green)),
                        icon: const Icon(Icons.filter_list, size: 18, color: Colors.green),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Departments', style: TextStyle(fontSize: 13)),
                          ),
                          ...uniqueDepartmentNames.map((name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name, style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDepartmentFilter = val;
                          });
                        },
                      ),
                    ),
                  ),
                const VerticalDivider(width: 20, indent: 12, endIndent: 12),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                  onPressed: _fetchEmployees,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Builder(
            builder: (context) {
              // Group by role to count "same role"
              final Map<String, int> counts = {};
              for (var e in filteredEmployees) {
                final role = e.role ?? 'Unknown';
                counts[role] = (counts[role] ?? 0) + 1;
              }
              final sortedRoles = counts.keys.toList()..sort();

              // Further filter by selected role chip
              final finalFilteredEmployees = filteredEmployees.where((e) {
                return _selectedRoleFilter == null || e.role == _selectedRoleFilter;
              }).toList();

              if (query.isEmpty && _employees.isEmpty) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.green.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sortedRoles.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // "All" chip
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRoleFilter = null;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedRoleFilter == null ? Colors.green : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.shade200),
                                  boxShadow: _selectedRoleFilter == null ? [
                                    BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                                  ] : null,
                                ),
                                child: Text(
                                  'All: ${filteredEmployees.length}',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRoleFilter == null ? Colors.white : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                            ...sortedRoles.map((role) {
                              final isSelected = _selectedRoleFilter == role;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedRoleFilter = null;
                                    } else {
                                      _selectedRoleFilter = role;
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade200),
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                                    ] : null,
                                  ),
                                  child: Text(
                                    '$role: ${counts[role]}',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: ManagementListWidget(
              items: filteredEmployees.where((e) => _selectedRoleFilter == null || e.role == _selectedRoleFilter).map((e) => ManagementListItem(
                id: e.id,
                title: e.name,
                subtitle: '${e.role} • ${e.email}',
                icon: Icons.person_outline,
                iconColor: const Color(0xFF059669),
                badge: e.role,
                badgeColor: Colors.blue,
                actions: [
                  ManagementAction(
                    label: 'View',
                    icon: Icons.remove_red_eye,
                    color: const Color(0xFF2563EB),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ModernDetailsDialog(
                          title: 'Employee Details',
                          details: [
                            DetailRow(label: 'Name', value: e.name),
                            DetailRow(label: 'ID', value: e.id),
                            DetailRow(label: 'Password', value: e.password),
                            DetailRow(label: 'Role', value: e.role ?? '-'),
                            DetailRow(label: 'Department', value: e.department ?? '-'),
                            DetailRow(label: 'Email', value: e.email ?? '-'),
                            DetailRow(label: 'Phone', value: e.phone ?? '-'),
                            DetailRow(label: 'College', value: e.collegeId),
                          ],
                        ),
                      );
                    },
                  ),
                  ManagementAction(
                    label: 'Edit',
                    icon: Icons.edit,
                    color: const Color(0xFF16A34A),
                    onPressed: () async {
                      final updatedEmployee = await Navigator.of(context).push<Employee>(
                        MaterialPageRoute(
                          builder: (context) => AddEditEmployeeScreen(
                            employee: e,
                            collegeId: widget.collegeId,
                            collegeType: widget.collegeType,
                          ),
                        ),
                      );
                      if (updatedEmployee != null) {
                        await Provider.of<EmployeeProvider>(context, listen: false)
                            .updateEmployee(e.id, updatedEmployee);
                        
                        // Auto-assign HOD to equipments if role is HOD
                        if (updatedEmployee.role == 'HOD' && updatedEmployee.department != null) {
                          await Provider.of<EquipmentProvider>(context, listen: false)
                              .assignHODToDepartmentEquipments(widget.collegeId, updatedEmployee.department!, updatedEmployee.id);
                        }

                        await _fetchEmployees();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Employee updated successfully.')),
                        );
                      }
                    },
                  ),
                  ManagementAction(
                    label: 'Delete',
                    icon: Icons.delete,
                    color: const Color(0xFFDC2626),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Employee'),
                          content: const Text('Are you sure you want to delete this employee?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await Provider.of<EmployeeProvider>(context, listen: false)
                            .deleteEmployee(e.id);
                        await _fetchEmployees();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Employee deleted.')),
                        );
                      }
                    },
                  ),
                ],
              )).toList(),
              emptyMessage: query.isEmpty ? 'No employees found. Add one to get started!' : 'No employees match your search.',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
          // Ensure departments are fetched before checking
          await departmentProvider.fetchDepartmentsForCollege(widget.collegeId);
          final departments = departmentProvider.getDepartmentsForCollege(widget.collegeId);
          
          if (departments == null || departments.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Create departments first! Employees must be assigned to departments.'),
                duration: Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final newEmployee = await Navigator.of(context).push<Employee>(
            MaterialPageRoute(
              builder: (context) => AddEditEmployeeScreen(
                collegeId: widget.collegeId,
                collegeType: widget.collegeType,
              ),
            ),
          );
          if (newEmployee != null) {
            await Provider.of<EmployeeProvider>(context, listen: false)
                .addEmployee(newEmployee);
            
            // Auto-assign HOD to equipments if role is HOD
            if (newEmployee.role == 'HOD' && newEmployee.department != null) {
              await Provider.of<EquipmentProvider>(context, listen: false)
                  .assignHODToDepartmentEquipments(widget.collegeId, newEmployee.department!, newEmployee.id);
            }

            await _fetchEmployees();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee added successfully.')),
            );
          }
        },
        tooltip: 'Add Employee',
        child: const Icon(Icons.add),
      ),
    );
  }
}
