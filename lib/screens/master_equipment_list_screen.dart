import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/providers/requirements_provider.dart';

class MasterEquipmentListScreen extends StatefulWidget {
  const MasterEquipmentListScreen({super.key});

  @override
  State<MasterEquipmentListScreen> createState() => _MasterEquipmentListScreenState();
}

class _MasterEquipmentListScreenState extends State<MasterEquipmentListScreen> {
  // Store selected capacity for each course
  final Map<String, String?> _selectedCapacities = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RequirementsProvider>(context);
    final requirements = provider.requirements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Equipment List'),
      ),
      body: ListView.builder(
        itemCount: requirements.length,
        itemBuilder: (context, courseIndex) {
          String courseName = requirements.keys.elementAt(courseIndex);
          Map<String, Map<String, Map<String, dynamic>>> courseData = requirements[courseName]!;

          final capacities = provider.getCapacitiesForCourse(courseName);
          _selectedCapacities.putIfAbsent(courseName, () => null);
          String? currentCapacity = _selectedCapacities[courseName];

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    courseName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String?>(
                        value: currentCapacity,
                        hint: const Text('All Equipment'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Equipment')),
                          ...capacities.map((c) => DropdownMenuItem(value: c, child: Text('Seats: $c'))),
                        ],
                        onChanged: (val) => setState(() => _selectedCapacities[courseName] = val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () => _showAddEquipmentDialog(context, courseName),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (currentCapacity == null)
                  _buildGlobalList(context, courseName, courseData)
                else
                  _buildCapacityWiseList(context, courseName, currentCapacity, courseData[currentCapacity]!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlobalList(BuildContext context, String courseName, Map<String, Map<String, Map<String, dynamic>>> courseData) {
    Set<String> courseEquipments = {};
    courseData.forEach((capacity, capacityData) {
      capacityData.forEach((department, deptData) {
        if (deptData.containsKey('equipments')) {
          Map<String, dynamic> equipments = Map<String, dynamic>.from(deptData['equipments']);
          courseEquipments.addAll(equipments.keys);
        }
      });
    });

    List<String> sortedEquipments = courseEquipments.toList()..sort();

    return Column(
      children: sortedEquipments.map((equipment) {
        return ListTile(
          leading: const Icon(Icons.settings),
          title: Text(equipment),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: () => _showEditEquipmentDialog(context, courseName, equipment),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, courseName, equipment),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCapacityWiseList(BuildContext context, String courseName, String capacity, Map<String, Map<String, dynamic>> capacityData) {
    List<Map<String, dynamic>> flatList = [];
    capacityData.forEach((deptName, deptData) {
      if (deptData.containsKey('equipments')) {
        Map<String, dynamic> equipments = Map<String, dynamic>.from(deptData['equipments']);
        equipments.forEach((name, count) {
          flatList.add({
            'name': name,
            'dept': deptName,
            'count': count,
          });
        });
      }
    });

    flatList.sort((a, b) => a['name'].compareTo(b['name']));

    if (flatList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No equipment defined for this capacity.'),
      );
    }

    return Column(
      children: flatList.map((item) {
        return ListTile(
          title: Text(item['name']),
          subtitle: Text(item['dept']),
          trailing: SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${item['count']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                  onPressed: () => _showEditCountDialog(context, courseName, capacity, item['dept'], item['name'], item['count']),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showEditCountDialog(BuildContext context, String course, String capacity, String dept, String name, dynamic currentCount) {
    final countController = TextEditingController(text: currentCount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Count: $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity: $capacity | Dept: $dept', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              decoration: const InputDecoration(labelText: 'Required Count'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newCount = int.tryParse(countController.text) ?? 0;
              Provider.of<RequirementsProvider>(context, listen: false)
                  .updateEquipmentCount(course, capacity, dept, name, newCount);
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context, String courseName) {
    final provider = Provider.of<RequirementsProvider>(context, listen: false);
    final capacities = provider.getCapacitiesForCourse(courseName);
    final departments = provider.getDepartmentsForCourse(courseName);
    
    String? selectedCapacity = capacities.isNotEmpty ? capacities.first : null;
    String? selectedDepartment = departments.isNotEmpty ? departments.first : null;
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Equipment to $courseName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCapacity,
                  decoration: const InputDecoration(labelText: 'Seat Capacity'),
                  items: capacities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCapacity = val),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setDialogState(() => selectedDepartment = val),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Equipment Name'),
                ),
                TextField(
                  controller: countController,
                  decoration: const InputDecoration(labelText: 'Required Count'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedCapacity != null && selectedDepartment != null) {
                  provider.addEquipmentToRequirement(
                    courseName,
                    selectedCapacity!,
                    selectedDepartment!,
                    nameController.text.trim(),
                    int.tryParse(countController.text) ?? 1,
                  );
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

  void _showEditEquipmentDialog(BuildContext context, String courseName, String oldName) {
    final nameController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Equipment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will rename "$oldName" across all departments and capacities in $courseName.', 
                 style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'New Equipment Name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Provider.of<RequirementsProvider>(context, listen: false)
                    .renameEquipmentInCourse(courseName, oldName, nameController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename Everywhere'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String courseName, String equipmentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to remove "$equipmentName" from all departments and capacities in $courseName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<RequirementsProvider>(context, listen: false)
                  .deleteEquipmentFromCourse(courseName, equipmentName);
              Navigator.pop(ctx);
            },
            child: const Text('Delete Everywhere', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
