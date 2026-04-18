import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/requirements_provider.dart';
import 'package:supreme_institution/data/department_group.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/equipment.dart'; // Add this import
import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/models/employee.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';

class AddEditEquipmentScreen extends StatefulWidget {
  final String collegeName;
  final Equipment? equipment; // Pass existing equipment for editing

  const AddEditEquipmentScreen({
    super.key,
    required this.collegeName,
    this.equipment,
  });

  @override
  State<AddEditEquipmentScreen> createState() => _AddEditEquipmentScreenState();
}

class _AddEditEquipmentScreenState extends State<AddEditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _statusController = TextEditingController();
  final _mfgController = TextEditingController();
  final _serialController = TextEditingController();
  final _costController = TextEditingController();

  // Equipment Group with Autocomplete
  final _groupController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _equipmentType = 'Non-Critical';
  String _equipmentMode = 'Portable';
  String _serviceStatus = 'Active';
  bool _hasWarranty = false;
  DateTime? _installationDate;
  DateTime? _warrantyUptoDate;

  List<String> _equipmentNames = [];
  List<String> _departmentSuggestions = [];
  List<String> _groupSuggestions = [];
  String? _selectedEquipment;
  String? _selectedDepartment; // Changed from TextEditingController
  List<String> _selectedEmployeeIds = []; // Multi-select employee assignment
  College? _college;
  final _equipmentNameFocusNode = FocusNode();

  @override
  void dispose() {
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
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    
    print('AddEditEquipmentScreen: Accessed CollegeProvider.');
    try {
      _college = collegeProvider.colleges.firstWhere((c) => c.name == widget.collegeName);
      print('AddEditEquipmentScreen: College found: ${_college!.name}, type: ${_college!.type}, seats: ${_college!.seats}');
      _loadEquipmentNames(_college!.type, _college!.seats);
      
      // Fetch departments and employees for the college
      departmentProvider.fetchDepartmentsForCollege(_college!.id);
      employeeProvider.fetchEmployees();
    } catch (e) {
      print('AddEditEquipmentScreen: College not found for name: ${widget.collegeName}. Error: $e');
      _college = null; // Ensure _college is null if not found
    }

    if (widget.equipment != null) {
      print('AddEditEquipmentScreen: Editing existing equipment: ${widget.equipment!.name}');
      _selectedEquipment = widget.equipment!.name;
      _selectedDepartment = widget.equipment!.department;
      _selectedEmployeeIds = widget.equipment!.assignedEmployeeIds ?? [];
      _statusController.text = widget.equipment!.status;
      _groupController.text = widget.equipment!.group;
      _mfgController.text = widget.equipment!.manufacturer;
      _serialController.text = widget.equipment!.serialNo;
      _costController.text = widget.equipment!.purchasedCost.toString();
      _equipmentType = widget.equipment!.type;
      _equipmentMode = widget.equipment!.mode;
      _serviceStatus = widget.equipment!.service;
      _hasWarranty = widget.equipment!.hasWarranty;
      _installationDate = widget.equipment!.installationDate;
      _warrantyUptoDate = widget.equipment!.warrantyUpto;
    }
  }

  String _normalizeEquipmentName(String name) {
    // Remove content in parentheses like "(Supragingival)" or "(x2)"
    String normalized = name.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    
    if (normalized.isEmpty) return name;

    // Convert to Title Case
    List<String> words = normalized.toLowerCase().split(' ');
    words = words.map((word) {
      if (word.isEmpty) return word;
      if (word == '&' || word == 'and') return word;
      return word[0].toUpperCase() + word.substring(1);
    }).toList();
    
    normalized = words.join(' ');

    // Handle specific pluralization/variants noticed in data
    if (normalized == 'Dental Chairs And Unit') normalized = 'Dental Chairs And Units';
    if (normalized == 'Extraction Forceps Sets') normalized = 'Extraction Forceps Set';
    
    return normalized;
  }

  void _loadEquipmentNames(String collegeType, String seats) {
    print('AddEditEquipmentScreen: Attempting to load equipment for collegeType: "$collegeType", seats: "$seats"');
    
    // Normalize college type and seats to match keys in requirements data
    String normalizedCollegeType = '';
    final trimmedCollegeType = collegeType.trim().toUpperCase();
    if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
      normalizedCollegeType = 'BDS';
    } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
      normalizedCollegeType = 'MBBS';
    }

    final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
    final masterList = requirementsProvider.getUniqueEquipmentsForCourse(normalizedCollegeType);

    setState(() {
      _equipmentNames = masterList;
      _equipmentNames.sort(); // Sort for consistent order
      print('AddEditEquipmentScreen: Final loaded equipment names (count: ${_equipmentNames.length}): $_equipmentNames');
    });
  }

  void _onEquipmentSelected(String selection) {
    _selectedEquipment = selection;
    final Set<String> departments = {};
    final Set<String> groups = {};
    if (_college != null) {
      // Normalize college type and seats to match keys in requirements data
      String normalizedCollegeType = '';
      final trimmedCollegeType = _college!.type.trim().toUpperCase();
      if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
        normalizedCollegeType = 'BDS';
      } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
        normalizedCollegeType = 'MBBS';
      }

      final normalizedSeats = _college!.seats.trim();
      
      final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
      final dynamicRequirements = requirementsProvider.requirements;

      if (dynamicRequirements.containsKey(normalizedCollegeType) && dynamicRequirements[normalizedCollegeType]!.containsKey(normalizedSeats)) {
        final seatData = dynamicRequirements[normalizedCollegeType]![normalizedSeats]!;
        seatData.forEach((department, deptData) {
          if (deptData.containsKey('equipments')) {
            (deptData['equipments'] as Map<String, dynamic>).forEach((equipment, count) {
              if (_normalizeEquipmentName(equipment) == selection) {
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
      
      if (departmentName != null) {
        // Auto-select HOD of the selected department
        final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
        final hods = employeeProvider.employees.where((emp) =>
          emp.collegeId == _college?.id &&
          emp.departments.contains(departmentName) &&
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

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      if (widget.equipment != null) {
        // Editing existing equipment
        final updatedEquipment = widget.equipment!.copyWith(
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
          collegeId: _college!.id,
        );
        Navigator.of(context).pop(updatedEquipment);
        return;
      }

      // Adding new equipment(s)
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      
      List<Equipment> equipmentsToAdd = [];
      String collegeCode = _college?.collegeCode ?? '000';
      
      for (int i = 0; i < quantity; i++) {
        String nextId;
        if (equipmentsToAdd.isEmpty) {
          nextId = equipmentProvider.generateNextEquipmentId(collegeCode);
        } else {
          String lastId = equipmentsToAdd.last.id;
          int lastSeq = int.parse(lastId.substring(3));
          nextId = collegeCode + (lastSeq + 1).toString().padLeft(4, '0');
        }

        // Check for collisions
        if (equipmentProvider.equipments.any((e) => e.id == nextId)) {
          int currentSeq = int.parse(nextId.substring(3));
          while (equipmentProvider.equipments.any((e) => e.id == nextId)) {
            currentSeq++;
            nextId = collegeCode + currentSeq.toString().padLeft(4, '0');
          }
        }

        equipmentsToAdd.add(Equipment(
          id: nextId,
          qrcode: nextId,
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
          collegeId: _college!.id,
        ));
      }

      Navigator.of(context).pop(equipmentsToAdd);
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
                        // Also update parent state to reflect selection immediately if needed
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    validator: (value) {
                      if (_selectedEquipment == null) {
                        return 'Please select an equipment name.';
                      }
                      return null;
                    },
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
                    },
                    );
                    },
                    ),
                    if (widget.equipment == null)
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
                    // Department dropdown from available departments

              Consumer<DepartmentProvider>(
                builder: (context, departmentProvider, _) {
                  // Always show all departments for the college
                  final departments = _college != null 
                      ? departmentProvider.getDepartmentsForCollege(_college!.id)
                      : <Department>[];
                  
                  // If equipment is selected and has department suggestions, 
                  // pre-select if only one suggestion, but still show all departments
                  if (_selectedEquipment != null && 
                      _departmentSuggestions.isNotEmpty && 
                      _departmentSuggestions.length == 1 &&
                      _selectedDepartment == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _updateSelectedDepartment(_departmentSuggestions.first);
                      }
                    });
                  }
                  
                  if (departments.isEmpty) {
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Department*',
                        hintText: 'No Departments Available',
                      ),
                      hint: const Text('No Departments Available'),
                      items: const [],
                      onChanged: null,
                    );
                  }
                  
                  // Ensure unique department names to avoid "Duplicate value" error in Dropdown
                  final uniqueDeptNames = departments.map((d) {
                    return d.subSelectionType != null ? "${d.name} (${d.subSelectionType})" : d.name;
                  }).toSet().toList()..sort();
                  
                  // Ensure current department is in the list
                  if (_selectedDepartment != null && !uniqueDeptNames.contains(_selectedDepartment)) {
                    uniqueDeptNames.add(_selectedDepartment!);
                  }

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedDepartment,
                    decoration: const InputDecoration(labelText: 'Department*'),
                    hint: const Text('Select Department'),
                    selectedItemBuilder: (BuildContext context) {
                      return uniqueDeptNames.map((String name) {
                        return Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }).toList();
                    },
                    items: uniqueDeptNames.map((String name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      _updateSelectedDepartment(newValue);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a department';
                      }
                      return null;
                    },
                  );
                },
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status*'),
                validator: (value) => value!.isEmpty ? 'Please enter a status' : null,
              ),
              const SizedBox(height: 16),
              if (_groupSuggestions.length > 1)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Equipment Group'),
                  initialValue: _groupController.text.isEmpty ? null : _groupController.text,
                  selectedItemBuilder: (BuildContext context) {
                    return _groupSuggestions.map((String group) {
                      return Text(
                        group,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                  items: _groupSuggestions.map((String group) {
                    return DropdownMenuItem<String>(
                      value: group,
                      child: Text(
                        group,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _groupController.text = newValue!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please select a group' : null,
                )
              else
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
                isExpanded: true,
                initialValue: _equipmentType,
                decoration: const InputDecoration(labelText: 'Equipment Type'),
                selectedItemBuilder: (BuildContext context) {
                  return ['Critical', 'Non-Critical'].map((label) {
                    return Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: ['Critical', 'Non-Critical'].map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _equipmentType = value!),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _equipmentMode,
                decoration: const InputDecoration(labelText: 'Equipment Mode'),
                selectedItemBuilder: (BuildContext context) {
                  return ['Mercury', 'Electrical', 'Portable', 'Hydrolic'].map((label) {
                    return Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: ['Mercury', 'Electrical', 'Portable', 'Hydrolic'].map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _equipmentMode = value!),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _serviceStatus,
                decoration: const InputDecoration(labelText: 'Service Status'),
                selectedItemBuilder: (BuildContext context) {
                  return ['Active', 'Non-Active'].map((label) {
                    return Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: ['Active', 'Non-Active'].map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _serviceStatus = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Installation Date: ${_installationDate == null ? 'Not Set' : DateFormat.yMd().format(_installationDate!)}',
                    ),
                  ),
                  TextButton(
                    child: const Text('Select Date'),
                    onPressed: () => _selectDate(context, (date) => setState(() => _installationDate = date)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Warranty', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Yes'),
                      value: true,
                      groupValue: _hasWarranty,
                      onChanged: (value) => setState(() => _hasWarranty = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No'),
                      value: false,
                      groupValue: _hasWarranty,
                      onChanged: (value) => setState(() => _hasWarranty = value!),
                    ),
                  ),
                ],
              ),
              if (_hasWarranty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Warranty Upto: ${_warrantyUptoDate == null ? 'Not Set' : DateFormat.yMd().format(_warrantyUptoDate!)}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Select Date'),
                      onPressed: () => _selectDate(context, (date) => setState(() => _warrantyUptoDate = date)),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Multi-select Employee assignment - filtered by selected department
              Builder(
                builder: (context) {
                  final employeeProvider = Provider.of<EmployeeProvider>(context, listen: true);
                  
                  // Get employees for this college
                  final collegeEmployees = _college != null
                      ? employeeProvider.employees
                          .where((emp) => emp.collegeId == _college!.id)
                          .toList()
                      : <Employee>[];
                  
                  // Check if department is selected (not null and not empty)
                  final hasDepartmentSelected = _selectedDepartment != null && 
                      _selectedDepartment!.isNotEmpty;
                  
                  // Filter employees by selected department
                  final departmentEmployees = hasDepartmentSelected
                      ? collegeEmployees
                          .where((emp) => emp.departments.contains(_selectedDepartment))
                          .toList()
                      : <Employee>[];
                  
                  String displayText;
                  if (!hasDepartmentSelected) {
                    displayText = 'Select Department First';
                  } else if (departmentEmployees.isEmpty) {
                    displayText = 'No Employees in Selected Department';
                  } else if (_selectedEmployeeIds.isEmpty) {
                    displayText = 'Select Employees (Optional)';
                  } else {
                    final names = departmentEmployees
                        .where((e) => _selectedEmployeeIds.contains(e.id))
                        .map((e) => e.name)
                        .join(', ');
                    displayText = names;
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign to Employees',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: hasDepartmentSelected && departmentEmployees.isNotEmpty
                            ? () => _showMultiSelectEmployees(departmentEmployees)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    color: hasDepartmentSelected && departmentEmployees.isNotEmpty
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
