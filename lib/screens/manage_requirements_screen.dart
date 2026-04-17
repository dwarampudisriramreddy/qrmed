import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/requirements_provider.dart';
import 'package:supreme_institution/screens/master_equipment_list_screen.dart';

class ManageRequirementsScreen extends StatefulWidget {
  const ManageRequirementsScreen({super.key});

  @override
  _ManageRequirementsScreenState createState() =>
      _ManageRequirementsScreenState();
}

class _ManageRequirementsScreenState extends State<ManageRequirementsScreen> {
  Map<String, Map<String, Map<String, Map<String, dynamic>>>>? _localRequirements;

  void _initLocalRequirements(RequirementsProvider provider) {
    if (_localRequirements == null) {
      _localRequirements = provider.deepCopyRequirements(provider.requirements);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RequirementsProvider>(context);
    _initLocalRequirements(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requirements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.green),
            tooltip: 'Add New Course',
            onPressed: _showAddCourseDialog,
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Master Equipment List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MasterEquipmentListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              provider.updateRequirements(_localRequirements!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Requirements saved successfully')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _localRequirements == null 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _localRequirements!.length,
        itemBuilder: (context, courseIndex) {
          String courseName = _localRequirements!.keys.elementAt(courseIndex);
          Map<String, Map<String, Map<String, dynamic>>> courseData =
              _localRequirements![courseName]!;

          return ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    courseName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                  tooltip: 'Add Capacity',
                  onPressed: () => _showAddCapacityDialog(courseName),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () => _showEditCourseDialog(courseName),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteCourse(courseName),
                ),
              ],
            ),
            children: courseData.keys.map((capacity) {
              Map<String, Map<String, dynamic>> capacityData =
                  courseData[capacity]!;

              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Capacity: $capacity Seats')),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_business, size: 20, color: Colors.green),
                          tooltip: 'Add Department',
                          onPressed: () => _showAddDepartmentDialog(courseName, capacity),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () => _showEditCapacityDialog(courseName, capacity),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteCapacity(courseName, capacity),
                        ),
                      ],
                    ),
                  ],
                ),
                children: capacityData.keys.map((department) {
                  Map<String, dynamic> departmentData =
                      capacityData[department]!;

                  return ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(department)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              onPressed: () => _showEditDepartmentDialog(courseName, capacity, department),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _deleteDepartment(courseName, capacity, department),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      _buildItemList(
                        'Equipments',
                        departmentData['equipments'],
                        courseName,
                        capacity,
                        department,
                        isEquipment: true,
                      ),
                      _buildItemList(
                        'Employees',
                        departmentData['employees'],
                        courseName,
                        capacity,
                        department,
                        isEquipment: false,
                      ),
                    ],
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showAddCourseDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Course'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Course Name (e.g., BDS)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _localRequirements![name] = {};
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(String oldName) {
    final nameController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Course'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Course Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                setState(() {
                  final data = _localRequirements!.remove(oldName);
                  _localRequirements![newName] = data!;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCourse(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete the course "$name"? This will remove all associated capacities, departments, and items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _localRequirements!.remove(name);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCapacityDialog(String course) {
    final capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Capacity'),
        content: TextField(
          controller: capacityController,
          decoration: const InputDecoration(labelText: 'Capacity (e.g., 100)'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final cap = capacityController.text.trim();
              if (cap.isNotEmpty) {
                setState(() {
                  _localRequirements![course]![cap] = {};
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCapacityDialog(String course, String oldCap) {
    final capacityController = TextEditingController(text: oldCap);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Capacity'),
        content: TextField(
          controller: capacityController,
          decoration: const InputDecoration(labelText: 'Capacity'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newCap = capacityController.text.trim();
              if (newCap.isNotEmpty && newCap != oldCap) {
                setState(() {
                  final data = _localRequirements![course]!.remove(oldCap);
                  _localRequirements![course]![newCap] = data!;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCapacity(String course, String capacity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Capacity'),
        content: Text('Are you sure you want to delete the capacity "$capacity"? This will remove all associated departments and items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _localRequirements![course]!.remove(capacity);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDepartmentDialog(String course, String capacity) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Department Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _localRequirements![course]![capacity]![name] = {
                    'equipments': <String, dynamic>{},
                    'employees': <String, dynamic>{},
                  };
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDepartmentDialog(String course, String capacity, String oldName) {
    final nameController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Department'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Department Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                setState(() {
                  final deptData = _localRequirements![course]![capacity]!.remove(oldName);
                  _localRequirements![course]![capacity]![newName] = deptData!;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDepartment(String course, String capacity, String department) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete the department "$department"? This will remove all associated equipments and employees.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _localRequirements![course]![capacity]!.remove(department);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(
    String title,
    Map<String, dynamic> items,
    String course,
    String capacity,
    String dept, {
    required bool isEquipment,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
                onPressed: () => _showAddItemDialog(course, capacity, dept, isEquipment),
              ),
            ],
          ),
          ...items.keys.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 40,
                      child: TextFormField(
                        initialValue: items[item].toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            items[item] = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        items.remove(item);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          const Divider(),
        ],
      ),
    );
  }

  void _showAddItemDialog(String course, String capacity, String dept, bool isEquipment) {
    final provider = Provider.of<RequirementsProvider>(context, listen: false);
    final masterList = isEquipment ? provider.getUniqueEquipmentsForCourse(course) : <String>[];
    
    String? selectedItem;
    final customItemController = TextEditingController();
    final countController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add ${isEquipment ? 'Equipment' : 'Employee'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEquipment && masterList.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedItem,
                  decoration: const InputDecoration(labelText: 'Select from Master List'),
                  items: masterList.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setDialogState(() => selectedItem = val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('OR enter new:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
              TextField(
                controller: customItemController,
                decoration: InputDecoration(
                  labelText: isEquipment ? 'New Equipment Name' : 'Employee Role',
                  hintText: 'Enter name manually',
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && selectedItem != null) {
                    setDialogState(() => selectedItem = null);
                  }
                },
              ),
              TextField(
                controller: countController,
                decoration: const InputDecoration(labelText: 'Required Count'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final itemName = (customItemController.text.isNotEmpty) 
                    ? customItemController.text.trim() 
                    : selectedItem;
                
                if (itemName != null && itemName.isNotEmpty) {
                  setState(() {
                    final targetMap = isEquipment 
                        ? _localRequirements![course]![capacity]![dept]!['equipments']
                        : _localRequirements![course]![capacity]![dept]!['employees'];
                    
                    targetMap[itemName] = int.tryParse(countController.text) ?? 1;
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
