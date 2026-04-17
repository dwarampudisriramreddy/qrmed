import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/data/department_group.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';

import 'package:supreme_institution/providers/requirements_provider.dart';

class AdminAddEquipmentScreen extends StatefulWidget {
  const AdminAddEquipmentScreen({super.key});

  @override
  State<AdminAddEquipmentScreen> createState() => _AdminAddEquipmentScreenState();
}

class _AdminAddEquipmentScreenState extends State<AdminAddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _statusController = TextEditingController(text: 'Working');
  final _mfgController = TextEditingController();
  final _serialController = TextEditingController();
  final _costController = TextEditingController();
  final _groupController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _equipmentType = 'Non-Critical';
  String _equipmentMode = 'Portable';
  String _serviceStatus = 'Active';
  bool _hasWarranty = false;
  DateTime? _installationDate = DateTime.now();
  DateTime? _warrantyUptoDate;

  List<String> _equipmentNames = [];
  List<String> _departmentSuggestions = [];
  List<String> _groupSuggestions = [];
  
  String? _selectedEquipment;
  String? _selectedDepartment;
  List<String> _selectedEmployeeIds = [];
  College? _selectedCollege;
  final _equipmentNameFocusNode = FocusNode();

  @override
  void dispose() {
    _idController.dispose();
    _statusController.dispose();
    _mfgController.dispose();
    _serialController.dispose();
    _costController.dispose();
    _groupController.dispose();
    _quantityController.dispose();
    _equipmentNameFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
    Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
  }

  void _loadEquipmentNames(String collegeType, String seats) {
    String normalizedCollegeType = '';
    final trimmedCollegeType = collegeType.trim().toUpperCase();
    if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
      normalizedCollegeType = 'BDS';
    } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
      normalizedCollegeType = 'MBBS';
    }

    // Use RequirementsProvider for the full master list for that type
    final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
    final masterList = requirementsProvider.getUniqueEquipmentsForCourse(normalizedCollegeType);

    setState(() {
      _equipmentNames = masterList;
      _equipmentNames.sort();
    });
  }

  void _onEquipmentSelected(String selection) {
    _selectedEquipment = selection;
    final Set<String> departments = {};
    final Set<String> groups = {};
    
    if (_selectedCollege != null) {
      String normalizedCollegeType = '';
      final trimmedCollegeType = _selectedCollege!.type.trim().toUpperCase();
      if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
        normalizedCollegeType = 'BDS';
      } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
        normalizedCollegeType = 'MBBS';
      }

      final normalizedSeats = _selectedCollege!.seats.trim();
      
      final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
      final dynamicRequirements = requirementsProvider.requirements;

      if (dynamicRequirements.containsKey(normalizedCollegeType) && dynamicRequirements[normalizedCollegeType]!.containsKey(normalizedSeats)) {
        final seatData = dynamicRequirements[normalizedCollegeType]![normalizedSeats]!;
        seatData.forEach((department, deptData) {
          if (deptData.containsKey('equipments')) {
            (deptData['equipments'] as Map<String, dynamic>).forEach((equipment, count) {
              if (equipment == selection) {
                departments.add(department);
                if (departmentGroup.containsKey(department)) {
                  groups.add(departmentGroup[department]!);
                }
              }
            });
          }
        });
      }
    }

    setState(() {
      _departmentSuggestions = departments.toList();
      _groupSuggestions = groups.toList();
      if (_departmentSuggestions.length == 1) {
        _updateSelectedDepartment(_departmentSuggestions.first);
      } else {
        _selectedDepartment = null;
        _selectedEmployeeIds = [];
      }
      if (_groupSuggestions.length == 1) {
        _groupController.text = _groupSuggestions.first;
      } else {
        _groupController.clear();
      }
    });
  }

  void _updateSelectedDepartment(String? departmentName) {
    setState(() {
      _selectedDepartment = departmentName;
      _selectedEmployeeIds = [];
      
      if (departmentName != null && _selectedCollege != null) {
        // Auto-select HOD of the selected department
        final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
        final hods = employeeProvider.employees.where((emp) => 
          emp.collegeId == _selectedCollege!.id && 
          emp.department == departmentName && 
          emp.role == 'HOD'
        ).toList();
        
        if (hods.isNotEmpty) {
          _selectedEmployeeIds = hods.map((h) => h.id).toList();
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCollege == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a college')));
        return;
      }

      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      
      final startIdStr = _idController.text.trim();
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      final startId = int.tryParse(startIdStr);

      if (startId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid ID format')));
        return;
      }

      List<Equipment> equipmentsToAdd = [];
      for (int i = 0; i < quantity; i++) {
        final currentId = (startId + i).toString();
        
        // Basic check for existing ID in local state (optional but good)
        if (equipmentProvider.equipments.any((e) => e.id == currentId)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Equipment with ID $currentId already exists')));
          return;
        }

        equipmentsToAdd.add(Equipment(
          id: currentId,
          qrcode: currentId,
          name: _selectedEquipment!,
          group: _groupController.text.trim(),
          manufacturer: _mfgController.text.trim(),
          type: _equipmentType,
          mode: _equipmentMode,
          serialNo: _serialController.text.trim(),
          department: _selectedDepartment ?? '',
          installationDate: _installationDate ?? DateTime.now(),
          status: _statusController.text.trim(),
          service: _serviceStatus,
          purchasedCost: double.tryParse(_costController.text.trim()) ?? 0.0,
          hasWarranty: _hasWarranty,
          warrantyUpto: _hasWarranty ? _warrantyUptoDate : null,
          assignedEmployeeIds: _selectedEmployeeIds,
          collegeId: _selectedCollege!.id,
        ));
      }

      try {
        await equipmentProvider.addMultipleEquipments(equipmentsToAdd);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$quantity equipment(s) added successfully')));
        _idController.clear();
        _mfgController.clear();
        _serialController.clear();
        _costController.clear();
        _quantityController.text = '1';
        setState(() {
          _selectedEquipment = null;
          _selectedDepartment = null;
          _selectedEmployeeIds = [];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding equipment: $e')));
      }
    }
  }

  void _showMultiSelectEmployees(List<Employee> departmentEmployees) async {
    final List<String>? results = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign to Employees'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: departmentEmployees.map((employee) {
                    final isChecked = _selectedEmployeeIds.contains(employee.id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text('${employee.name} (${employee.role})'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedEmployeeIds.add(employee.id);
                          } else {
                            _selectedEmployeeIds.remove(employee.id);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context, _selectedEmployeeIds),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (results != null) {
      setState(() {
        _selectedEmployeeIds = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final collegeProvider = Provider.of<CollegeProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Equipment Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<College>(
                isExpanded: true,
                value: _selectedCollege,
                decoration: const InputDecoration(labelText: 'Select College*'),
                items: collegeProvider.colleges.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (college) {
                  setState(() {
                    _selectedCollege = college;
                    _selectedDepartment = null;
                    _selectedEquipment = null;
                    _selectedEmployeeIds = [];
                    if (college != null) {
                      _idController.text = college.collegeCode;
                      _loadEquipmentNames(college.type, college.seats);
                      departmentProvider.fetchDepartmentsForCollege(college.id);
                    }
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'Manual 7-Digit ID*', hintText: 'e.g., 1010001'),
                keyboardType: TextInputType.number,
                maxLength: 7,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 7) return 'Must be 7 digits';
                  if (_selectedCollege != null && !v.startsWith(_selectedCollege!.collegeCode)) {
                    return 'Must start with college code ${_selectedCollege!.collegeCode}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity', hintText: 'Enter number of equipments to add'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final q = int.tryParse(v);
                  if (q == null || q <= 0) return 'Must be a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              RawAutocomplete<String>(
                focusNode: _equipmentNameFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _equipmentNames.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _onEquipmentSelected(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Sync controller with _selectedEquipment if needed
                  if (_selectedEquipment != null && controller.text != _selectedEquipment) {
                    controller.text = _selectedEquipment!;
                  } else if (_selectedEquipment == null && controller.text.isNotEmpty) {
                    controller.clear();
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Equipment Name*',
                      hintText: 'Type to search...',
                      suffixIcon: Icon(Icons.search, size: 20),
                    ),
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                    validator: (v) => _selectedEquipment == null ? 'Required' : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        width: 300,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(option, style: const TextStyle(fontSize: 14)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department*'),
                items: _selectedCollege == null 
                  ? [] 
                  : (() {
                      final depts = departmentProvider.getDepartmentsForCollege(_selectedCollege!.id);
                      final uniqueNames = depts.map((d) {
                        return d.subSelectionType != null ? "${d.name} (${d.subSelectionType})" : d.name;
                      }).toSet().toList()..sort();
                      if (_selectedDepartment != null && !uniqueNames.contains(_selectedDepartment)) {
                        uniqueNames.add(_selectedDepartment!);
                      }
                      return uniqueNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList();
                    })(),
                onChanged: (val) => _updateSelectedDepartment(val),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupController,
                decoration: const InputDecoration(labelText: 'Equipment Group'),
                readOnly: true,
              ),
              TextFormField(controller: _mfgController, decoration: const InputDecoration(labelText: 'Manufacturer')),
              TextFormField(controller: _serialController, decoration: const InputDecoration(labelText: 'Serial No.')),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Purchased Cost'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _equipmentType,
                decoration: const InputDecoration(labelText: 'Equipment Type'),
                items: ['Critical', 'Non-Critical'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _equipmentType = v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: _equipmentMode,
                decoration: const InputDecoration(labelText: 'Equipment Mode'),
                items: ['Mercury', 'Electrical', 'Portable', 'Hydrolic'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _equipmentMode = v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: _serviceStatus,
                decoration: const InputDecoration(labelText: 'Service Status'),
                items: ['Active', 'Non-Active'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _serviceStatus = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('Installation Date: ${DateFormat.yMd().format(_installationDate!)}')),
                  TextButton(child: const Text('Select Date'), onPressed: () => _selectDate(context, (d) => setState(() => _installationDate = d))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Warranty', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(child: RadioListTile<bool>(title: const Text('Yes'), value: true, groupValue: _hasWarranty, onChanged: (v) => setState(() => _hasWarranty = v!))),
                  Expanded(child: RadioListTile<bool>(title: const Text('No'), value: false, groupValue: _hasWarranty, onChanged: (v) => setState(() => _hasWarranty = v!))),
                ],
              ),
              if (_hasWarranty)
                Row(
                  children: [
                    Expanded(child: Text('Warranty Upto: ${_warrantyUptoDate == null ? 'Not Set' : DateFormat.yMd().format(_warrantyUptoDate!)}')),
                    TextButton(child: const Text('Select Date'), onPressed: () => _selectDate(context, (d) => setState(() => _warrantyUptoDate = d))),
                  ],
                ),
              const SizedBox(height: 24),
              Consumer<EmployeeProvider>(
                builder: (context, empProvider, _) {
                  final employees = _selectedCollege == null 
                    ? <Employee>[] 
                    : empProvider.employees.where((e) => e.collegeId == _selectedCollege!.id && e.department == _selectedDepartment).toList();
                  
                  String displayText;
                  if (_selectedCollege == null || _selectedDepartment == null) {
                    displayText = 'Select College & Department First';
                  } else if (employees.isEmpty) {
                    displayText = 'No Employees in Selected Department';
                  } else if (_selectedEmployeeIds.isEmpty) {
                    displayText = 'Select Employees (Optional)';
                  } else {
                    final names = employees
                        .where((e) => _selectedEmployeeIds.contains(e.id))
                        .map((e) => e.name)
                        .join(', ');
                    displayText = names;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assign to Employees', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: (_selectedDepartment != null && employees.isNotEmpty)
                          ? () => _showMultiSelectEmployees(employees)
                          : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              Expanded(child: Text(displayText, style: TextStyle(color: (_selectedDepartment != null && employees.isNotEmpty) ? Colors.black : Colors.grey), overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveForm,
                  child: const Text('Add Equipment'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
