import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Ensure this is imported
import 'package:supreme_institution/models/department.dart'; // Ensure this is imported
import 'package:supreme_institution/models/employee.dart'; // Ensure this is imported
import 'package:supreme_institution/providers/department_provider.dart'; // Ensure this is imported
import 'dart:math'; // Added for Random class
import 'package:english_words/english_words.dart' as english_words; // Added for meaningful words

class AddEditEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  final String collegeId;
  final String collegeType; // 'Dental' or 'MBBS'

  const AddEditEmployeeScreen({
    super.key,
    this.employee,
    required this.collegeId,
    required this.collegeType,
  });

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  List<String> _selectedDepartments = [];
  String? _selectedRole;
  bool _obscurePassword = true;
  bool _assignAllEquipments = false;

  // Predefined roles based on college type, as per inspection data requirements.
  final Map<String, List<String>> _rolesByCollegeType = {
    'BDS': [
      'Principal',
      'HOD',
      'Professor',
      'Reader',
      'Senior Lecturer',
      'Tutor',
      'Student',
      'Non-Teaching Staff',
    ],
    'MBBS': [
      'Principal',
      'HOD',
      'Professor',
      'Associate Professor',
      'Assistant Professor',
      'Senior Resident',
      'Junior Resident',
      'Student',
      'Non-Teaching Staff',
    ],
  };

  late List<String> _availableRoles;

  @override
  void initState() {
    super.initState();
    // Normalize college type to match our map keys
    String normalizedType = widget.collegeType.toUpperCase();
    if (normalizedType == 'DENTAL') normalizedType = 'BDS';
    if (normalizedType == 'MEDICAL') normalizedType = 'MBBS';

    // Determine available roles based on the normalized college type.
    _availableRoles = _rolesByCollegeType[normalizedType] ?? [];

    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _emailController.text = widget.employee!.email ?? '';
      _phoneController.text = widget.employee!.phone ?? '';
      _passwordController.text = widget.employee!.password;
      _selectedDepartments = List<String>.from(widget.employee!.departments);
      // Ensure the existing role is valid, otherwise, it will be null.
      if (_availableRoles.contains(widget.employee!.role)) {
        _selectedRole = widget.employee!.role;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    final random = Random();
    String word = "";
    // Keep picking until we find a word with 6-10 letters
    while (word.length < 6 || word.length > 10) {
      word = english_words.all.elementAt(random.nextInt(english_words.all.length));
    }
    return word;
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final employeeId = widget.employee?.id ?? '${_nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@${widget.collegeId}';

      // For Principal roles, department is optional (can be null or empty)
      final isPrincipal = _selectedRole != null && 
          (_selectedRole!.contains('Principal') || _selectedRole!.contains('Dean'));

      if (!isPrincipal && _selectedDepartments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one department.')),
        );
        return;
      }

      final List<String> assignedEquipments = List<String>.from(widget.employee?.assignedEquipments ?? []);
      if (_assignAllEquipments) {
        // Use a special marker to indicate bulk assignment
        if (!assignedEquipments.contains('ASSIGN_ALL_IN_DEPT')) {
          assignedEquipments.add('ASSIGN_ALL_IN_DEPT');
        }
      }

      final newEmployee = Employee(
        id: employeeId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        collegeId: widget.collegeId,
        role: _selectedRole!,
        departments: _selectedDepartments,
        assignedEquipments: assignedEquipments,
      );
      Navigator.of(context).pop(newEmployee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final departments = departmentProvider.getDepartmentsForCollege(widget.collegeId);
    
    // Ensure unique department names (though subSelectionType was removed, we still handle consistency)
    final uniqueDepartmentNames = departments.map((d) {
      return (d.subSelectionType != null && d.subSelectionType!.isNotEmpty) 
          ? "${d.name} (${d.subSelectionType})" 
          : d.name;
    }).toSet().toList()..sort();
    
    final isPrincipal = _selectedRole != null && 
        (_selectedRole!.contains('Principal') || _selectedRole!.contains('Dean'));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Employee Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the employee name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _availableRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role, overflow: TextOverflow.ellipsis, maxLines: 1),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                isPrincipal ? 'Departments (Optional)' : 'Departments',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: uniqueDepartmentNames.map((name) {
                    return CheckboxListTile(
                      title: Text(name),
                      value: _selectedDepartments.contains(name),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedDepartments.add(name);
                          } else {
                            _selectedDepartments.remove(name);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              if (!isPrincipal && _selectedDepartments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Please select at least one department.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              // Option to assign all equipments in department
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Assign ALL equipments in selected departments',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
                  ),
                  subtitle: const Text(
                    'Turning this on will automatically assign every equipment from the chosen departments to this employee.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _assignAllEquipments,
                  onChanged: (val) {
                    setState(() {
                      _assignAllEquipments = val;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.vpn_key),
                        tooltip: 'Generate Password',
                        onPressed: () {
                          setState(() {
                            _passwordController.text = _generatePassword();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEmployee,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.employee == null ? 'Add Employee' : 'Update Employee',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
