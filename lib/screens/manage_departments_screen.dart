import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/requirements_provider.dart';
import '../widgets/modern_details_dialog.dart';
import '../widgets/management_list_widget.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  final College college;

  const ManageDepartmentsScreen({super.key, required this.college});

  @override
  _ManageDepartmentsScreenState createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DepartmentProvider>(context, listen: false)
          .fetchDepartmentsForCollege(widget.college.id);
    });
  }

  void _showEditDialog(Department department, List<String> departmentNames) {
    String? newSelectedDepartment = department.name;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Department',
                  style: TextStyle(color: Colors.blue)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: newSelectedDepartment,
                      selectedItemBuilder: (BuildContext context) {
                        return departmentNames.map((String deptName) {
                          return Text(
                            deptName,
                            style: const TextStyle(color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }).toList();
                      },
                      items: departmentNames.map((String deptName) {
                        return DropdownMenuItem<String>(
                          value: deptName,
                          child: Text(
                            deptName,
                            style: const TextStyle(color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          newSelectedDepartment = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Department Name',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    if (newSelectedDepartment != null) {
                      final updatedDepartment = Department(
                        id: department.id,
                        name: newSelectedDepartment!,
                        collegeId: department.collegeId,
                        subSelectionType: null,
                      );
                      await Provider.of<DepartmentProvider>(context,
                              listen: false)
                          .updateDepartment(updatedDepartment);
                      if (mounted) Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
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
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final requirementsProvider = Provider.of<RequirementsProvider>(context);
    
    final departments =
        departmentProvider.getDepartmentsForCollege(widget.college.id);

    final collegeType = widget.college.type;
    final collegeSeats = widget.college.seats;
    
    // First try the mapped key, then the raw type
    String typeKey = collegeType == 'Dental' ? 'BDS' : collegeType;
    if (!requirementsProvider.requirements.containsKey(typeKey)) {
        typeKey = collegeType;
    }
    
    final departmentNames = requirementsProvider.getDepartmentNames(typeKey, collegeSeats);

    final items = departments.map((department) {
      return ManagementListItem(
        id: department.id,
        title: department.name,
        subtitle: 'Department',
        icon: Icons.school,
        iconColor: Colors.blue,
        actions: [
          ManagementAction(
            label: 'Edit',
            icon: Icons.edit,
            color: Colors.blue,
            onPressed: () => _showEditDialog(department, departmentNames),
          ),
          ManagementAction(
            label: 'Delete',
            icon: Icons.delete,
            color: Colors.red,
            onPressed: () async {
              await Provider.of<DepartmentProvider>(context, listen: false)
                  .deleteDepartment(department.id, widget.college.id);
            },
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Departments'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedDepartment,
                          selectedItemBuilder: (BuildContext context) {
                            return departmentNames.map((String department) {
                              return Text(
                                department,
                                style: const TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            }).toList();
                          },
                          items: departmentNames.map((String department) {
                            return DropdownMenuItem<String>(
                              value: department,
                              child: Text(
                                department,
                                style: const TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDepartment = newValue;
                            });
                          },
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'Department Name',
                            labelStyle: TextStyle(color: Colors.blue),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 1.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a department';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final newDepartment = Department(
                              id: DateTime.now().toString(),
                              name: _selectedDepartment!,
                              collegeId: widget.college.id,
                              subSelectionType: null,
                            );
                            await Provider.of<DepartmentProvider>(context,
                                    listen: false)
                                .addDepartment(newDepartment);
                            setState(() {
                              _selectedDepartment = null;
                            });
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ManagementListWidget(
              items: items,
              emptyMessage: 'No departments added yet',
            ),
          ),
        ],
      ),
    );
  }
}
