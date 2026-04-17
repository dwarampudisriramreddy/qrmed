import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequirementsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _requirementsCollection;
  StreamSubscription? _requirementsSubscription;

  // Use the complex nested structure as the primary state
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> _requirements = {};
  
  // Mapping equipment names to the departments that use them
  Map<String, List<String>> _equipmentDepartments = {};

  Map<String, Map<String, Map<String, Map<String, dynamic>>>> get requirements => _requirements;
  Map<String, List<String>> get availableEquipment => _equipmentDepartments;

  RequirementsProvider() {
    _requirementsCollection = _firestore.collection('requirements_config');
    // Initialize with empty map - will be filled by listener
    _requirements = {};
    _prepareEquipmentData();
    startListeningToRequirements();
  }

  // Helper to get all unique equipment names for a course (The Master List)
  List<String> getUniqueEquipmentsForCourse(String course) {
    Set<String> equipmentNames = {};
    if (_requirements.containsKey(course)) {
      _requirements[course]!.forEach((capacity, departments) {
        departments.forEach((deptName, deptData) {
          if (deptData.containsKey('equipments')) {
            Map<String, dynamic> equipments = deptData['equipments'];
            equipmentNames.addAll(equipments.keys);
          }
        });
      });
    }
    return equipmentNames.toList()..sort();
  }

  // Rename an equipment name across all capacities and departments in a course
  Future<void> renameEquipmentInCourse(String course, String oldName, String newName) async {
    if (oldName == newName) return;
    
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (updated.containsKey(course)) {
      updated[course]!.forEach((capacity, departments) {
        departments.forEach((deptName, deptData) {
          if (deptData.containsKey('equipments')) {
            Map<String, dynamic> equipments = deptData['equipments'];
            if (equipments.containsKey(oldName)) {
              dynamic count = equipments.remove(oldName);
              equipments[newName] = count;
            }
          }
        });
      });
      await updateRequirements(updated);
    }
  }

  // Delete an equipment name across all capacities and departments in a course
  Future<void> deleteEquipmentFromCourse(String course, String equipmentName) async {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (updated.containsKey(course)) {
      updated[course]!.forEach((capacity, departments) {
        departments.forEach((deptName, deptData) {
          if (deptData.containsKey('equipments')) {
            Map<String, dynamic> equipments = deptData['equipments'];
            equipments.remove(equipmentName);
          }
        });
      });
      await updateRequirements(updated);
    }
  }

  // Update count of an equipment in a specific requirement
  Future<void> updateEquipmentCount(String course, String capacity, String department, String equipmentName, int newCount) async {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (updated.containsKey(course) && 
        updated[course]!.containsKey(capacity) && 
        updated[course]![capacity]!.containsKey(department)) {
      
      if (updated[course]![capacity]![department]!.containsKey('equipments')) {
        updated[course]![capacity]![department]!['equipments'][equipmentName] = newCount;
        await updateRequirements(updated);
      }
    }
  }

  // Add an equipment to a specific department and capacity in a course
  Future<void> addEquipmentToRequirement(String course, String capacity, String department, String equipmentName, int count) async {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (!updated.containsKey(course)) updated[course] = {};
    if (!updated[course]!.containsKey(capacity)) updated[course]![capacity] = {};
    if (!updated[course]![capacity]!.containsKey(department)) updated[course]![capacity]![department] = {'equipments': {}, 'employees': {}};
    
    Map<String, dynamic> deptData = updated[course]![capacity]![department]!;
    if (!deptData.containsKey('equipments')) {
      deptData['equipments'] = <String, dynamic>{};
    }
    
    Map<String, dynamic> equipments = deptData['equipments'];
    equipments[equipmentName] = count;
    
    await updateRequirements(updated);
  }

  // Add a department to a specific capacity in a course
  Future<void> addDepartmentToRequirement(String course, String capacity, String departmentName) async {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (!updated.containsKey(course)) updated[course] = {};
    if (!updated[course]!.containsKey(capacity)) updated[course]![capacity] = {};
    
    if (!updated[course]![capacity]!.containsKey(departmentName)) {
      updated[course]![capacity]![departmentName] = {
        'equipments': <String, dynamic>{},
        'employees': <String, dynamic>{}
      };
      await updateRequirements(updated);
    }
  }

  // Rename a department in a specific capacity in a course
  Future<void> renameDepartmentInRequirement(String course, String capacity, String oldName, String newName) async {
    if (oldName == newName) return;
    
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (updated.containsKey(course) && 
        updated[course]!.containsKey(capacity) && 
        updated[course]![capacity]!.containsKey(oldName)) {
      
      Map<String, Map<String, dynamic>> capacityData = updated[course]![capacity]!;
      capacityData[newName] = capacityData.remove(oldName)!;
      
      await updateRequirements(updated);
    }
  }

  // Delete a department from a specific capacity in a course
  Future<void> deleteDepartmentFromRequirement(String course, String capacity, String departmentName) async {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> updated = _deepCopyNestedMap(_requirements);
    
    if (updated.containsKey(course) && 
        updated[course]!.containsKey(capacity)) {
      
      updated[course]![capacity]!.remove(departmentName);
      await updateRequirements(updated);
    }
  }

  // Helper to get all unique departments for a course
  List<String> getDepartmentsForCourse(String course) {
    Set<String> departments = {};
    if (_requirements.containsKey(course)) {
      _requirements[course]!.forEach((capacity, depts) {
        departments.addAll(depts.keys);
      });
    }
    return departments.toList()..sort();
  }

  // Helper to get all capacities for a course
  List<String> getCapacitiesForCourse(String course) {
    if (_requirements.containsKey(course)) {
      return _requirements[course]!.keys.toList()..sort();
    }
    return [];
  }

  // Helper to get department names for a specific course and capacity
  List<String> getDepartmentNames(String course, String capacity) {
    if (_requirements.containsKey(course) && _requirements[course]!.containsKey(capacity)) {
      return _requirements[course]![capacity]!.keys.toList()..sort();
    }
    return [];
  }

  // Public wrapper for deep copy
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> deepCopyRequirements(Map<String, Map<String, Map<String, Map<String, dynamic>>>> source) {
    return _deepCopyNestedMap(source);
  }

  // Deep copy helper (existing)
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> _deepCopyNestedMap(Map<String, Map<String, Map<String, Map<String, dynamic>>>> source) {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> result = {};
    source.forEach((course, courseData) {
      Map<String, Map<String, Map<String, dynamic>>> capacities = {};
      courseData.forEach((capacity, capacityData) {
        Map<String, Map<String, dynamic>> departments = {};
        capacityData.forEach((dept, deptData) {
          Map<String, dynamic> data = {};
          deptData.forEach((key, value) {
            if (value is Map) {
              data[key] = Map<String, dynamic>.from(value);
            } else {
              data[key] = value;
            }
          });
          departments[dept] = data;
        });
        capacities[capacity] = departments;
      });
      result[course] = capacities;
    });
    return result;
  }

  // Start real-time listener for requirements
  void startListeningToRequirements() {
    _requirementsSubscription?.cancel();
    _requirementsSubscription = _requirementsCollection.doc('master_config').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _requirements = _castToNestedMap(data);
        _prepareEquipmentData();
        notifyListeners();
        print('Requirements updated from Firestore listener');
      } else {
        print('Requirements document does not exist in Firestore');
        _requirements = {};
        notifyListeners();
      }
    }, onError: (e) {
      print('Error listening to requirements: $e');
    });
  }

  // Fetch requirements from Firestore (stored as a single config document)
  Future<void> fetchRequirements() async {
    try {
      DocumentSnapshot doc = await _requirementsCollection.doc('master_config').get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _requirements = _castToNestedMap(data);
        _prepareEquipmentData();
        notifyListeners();
        print('Requirements loaded manually from Firestore');
      } else {
        print('Requirements not found in Firestore');
        _requirements = {};
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching requirements: $e');
    }
  }

  // Helper to cast dynamic map from Firestore back to our nested structure
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> _castToNestedMap(Map<String, dynamic> data) {
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> result = {};
    data.forEach((course, courseData) {
      if (courseData is Map) {
        Map<String, Map<String, Map<String, dynamic>>> capacities = {};
        courseData.forEach((capacity, capacityData) {
          if (capacityData is Map) {
            Map<String, Map<String, dynamic>> departments = {};
            capacityData.forEach((dept, deptData) {
              if (deptData is Map) {
                departments[dept] = Map<String, dynamic>.from(deptData);
              }
            });
            capacities[capacity] = departments;
          }
        });
        result[course] = capacities;
      }
    });
    return result;
  }

  // Update the entire requirements structure
  Future<void> updateRequirements(Map<String, Map<String, Map<String, Map<String, dynamic>>>> newRequirements) async {
    try {
      _requirements = newRequirements;
      _prepareEquipmentData();
      notifyListeners();

      // Save to Firestore
      await _requirementsCollection.doc('master_config').set(_requirements);
    } catch (e) {
      print('Error saving requirements: $e');
    }
  }

  void _prepareEquipmentData() {
    _equipmentDepartments.clear();
    _requirements.forEach((course, capacities) {
      capacities.forEach((capacity, departments) {
        departments.forEach((deptName, deptData) {
          if (deptData.containsKey('equipments')) {
            Map<String, dynamic> equipments = Map<String, dynamic>.from(deptData['equipments']);
            equipments.forEach((equipmentName, count) {
              if (!_equipmentDepartments.containsKey(equipmentName)) {
                _equipmentDepartments[equipmentName] = [];
              }
              if (!_equipmentDepartments[equipmentName]!.contains(deptName)) {
                _equipmentDepartments[equipmentName]!.add(deptName);
              }
            });
          }
        });
      });
    });
  }

  // Legacy support for flat structure if needed elsewhere, 
  // but most screens seem to want the nested map.
  List<Map<String, dynamic>> get requirementsList {
    List<Map<String, dynamic>> flat = [];
    _requirements.forEach((course, capacities) {
      capacities.forEach((capacity, departments) {
        departments.forEach((dept, data) {
          flat.add({
            'collegeType': course,
            'seats': capacity,
            'department': dept,
            'equipments': data['equipments'],
            'employees': data['employees'],
          });
        });
      });
    });
    return flat;
  }

  @override
  void dispose() {
    _requirementsSubscription?.cancel();
    super.dispose();
  }
}