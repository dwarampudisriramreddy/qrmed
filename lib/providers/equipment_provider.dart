
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';
import '../models/app_notification.dart';
import 'notification_provider.dart';

class EquipmentProvider with ChangeNotifier {
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');

  List<Equipment> _equipments = [];
  List<Equipment> get equipments => _equipments;

  Future<void> fetchEquipments() async {
    final snapshot = await _equipmentCollection.get();
    _equipments = snapshot.docs
        .map((doc) => Equipment.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<Equipment?> getEquipmentById(String equipmentId) async {
    final doc = await _equipmentCollection.doc(equipmentId).get();
    if (doc.exists) {
      return Equipment.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> addEquipment(Equipment equipment, {NotificationProvider? notificationProvider}) async {
    final normalizedEquipment = equipment.copyWith(
      status: equipment.status.trim(),
    );
    await _equipmentCollection.doc(normalizedEquipment.id).set(normalizedEquipment.toJson());
    
    // If a college adds a "Not Working" equipment initially
    if (notificationProvider != null && normalizedEquipment.status == 'Not Working') {
      await notificationProvider.addNotification(AppNotification(
        id: '',
        title: 'New Failure Reported',
        message: 'College ${normalizedEquipment.collegeId} added: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) in ${normalizedEquipment.department} as Not Working.',
        timestamp: DateTime.now(),
        targetUserId: 'admin',
        equipmentId: normalizedEquipment.id,
      ));
    }
    
    await fetchEquipments();
  }

  Future<void> addMultipleEquipments(List<Equipment> equipments) async {
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    
    for (var equipment in equipments) {
      final normalizedEquipment = equipment.copyWith(
        status: equipment.status.trim(),
      );
      batch.set(_equipmentCollection.doc(normalizedEquipment.id), normalizedEquipment.toJson());
    }
    
    await batch.commit();
    await fetchEquipments();
  }

  Future<void> updateEquipment(String id, Equipment updatedEquipment, {NotificationProvider? notificationProvider, String? updatedByRole}) async {
    print('DEBUG: EquipmentProvider: updateEquipment called for $id by role: $updatedByRole');
    final oldEquipment = _equipments.firstWhere((e) => e.id == id);
    final normalizedEquipment = updatedEquipment.copyWith(
      status: updatedEquipment.status.trim(),
    );
    
    print('DEBUG: EquipmentProvider: Status change: ${oldEquipment.status} -> ${normalizedEquipment.status}');
    
    await _equipmentCollection.doc(id).update(normalizedEquipment.toJson());

    if (notificationProvider != null) {
      print('DEBUG: EquipmentProvider: notificationProvider is NOT null, checking scenarios...');
      // Scenario 1: College sets status to Not Working -> Admin gets notification
      if (oldEquipment.status != 'Not Working' && normalizedEquipment.status == 'Not Working' && updatedByRole == 'college') {
        print('DEBUG: EquipmentProvider: Scenario 1 triggered (College -> Admin)');
        await notificationProvider.addNotification(AppNotification(
          id: '',
          title: 'Equipment Failure',
          message: 'College ${normalizedEquipment.collegeId} marked: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) in ${normalizedEquipment.department} as Not Working.',
          timestamp: DateTime.now(),
          targetUserId: 'admin',
          equipmentId: normalizedEquipment.id,
        ));
      }
      
      // Scenario 2: Admin sets status from Not Working to Working -> College gets notification
      if (oldEquipment.status == 'Not Working' && normalizedEquipment.status == 'Working' && updatedByRole == 'admin') {
        print('DEBUG: EquipmentProvider: Scenario 2 triggered (Admin -> College)');
        await notificationProvider.addNotification(AppNotification(
          id: '',
          title: 'Equipment Restored',
          message: 'Admin marked: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) in ${normalizedEquipment.department} as Working.',
          timestamp: DateTime.now(),
          targetUserId: normalizedEquipment.collegeId,
          equipmentId: normalizedEquipment.id,
        ));
      }

      // Scenario 3: Employee changes status -> Both Admin and College get notification
      if (updatedByRole == 'employee' && oldEquipment.status != normalizedEquipment.status) {
        print('DEBUG: EquipmentProvider: Scenario 3 triggered (Employee -> Admin & College)');
        final title = normalizedEquipment.status == 'Working' ? 'Equipment Restored' : 'Equipment Failure';
        final assignedEmpText = normalizedEquipment.assignedEmployeeIds != null && normalizedEquipment.assignedEmployeeIds!.isNotEmpty 
            ? normalizedEquipment.assignedEmployeeIds!.join(', ') 
            : 'Unassigned';
        final message = 'Employee(s) $assignedEmpText marked: ${normalizedEquipment.name} (ID: ${normalizedEquipment.id}) in ${normalizedEquipment.department} as ${normalizedEquipment.status}.';
        
        // Notify Admin
        print('DEBUG: EquipmentProvider: Sending notification to Admin. Message: $message');
        try {
          await notificationProvider.addNotification(AppNotification(
            id: '',
            title: title,
            message: message,
            timestamp: DateTime.now(),
            targetUserId: 'admin',
            equipmentId: normalizedEquipment.id,
          ));
          print('DEBUG: EquipmentProvider: Admin notification added successfully');
        } catch (e) {
          print('DEBUG ERROR: EquipmentProvider: Failed to add Admin notification: $e');
        }

        // Notify College
        print('DEBUG: EquipmentProvider: Sending notification to College: ${normalizedEquipment.collegeId}. Message: $message');
        try {
          await notificationProvider.addNotification(AppNotification(
            id: '',
            title: title,
            message: message,
            timestamp: DateTime.now(),
            targetUserId: normalizedEquipment.collegeId,
            equipmentId: normalizedEquipment.id,
          ));
          print('DEBUG: EquipmentProvider: College notification added successfully');
        } catch (e) {
          print('DEBUG ERROR: EquipmentProvider: Failed to add College notification: $e');
        }
      } else {
        if (updatedByRole == 'employee') {
          print('DEBUG: EquipmentProvider: Employee updated, but status did NOT change (${oldEquipment.status} == ${normalizedEquipment.status})');
        }
      }
    } else {
      print('DEBUG: EquipmentProvider: notificationProvider IS NULL. No notifications will be sent.');
    }

    await fetchEquipments();
  }

  Future<void> deleteEquipment(String id) async { // Changed from deleteProduct
    await _equipmentCollection.doc(id).delete();
    await fetchEquipments(); // Changed from fetchProducts
  }

  // NEW: Function to delete all equipments for a given college
  Future<void> deleteAllEquipmentsForCollege(String collegeName) async {
    final QuerySnapshot snapshot = await _equipmentCollection.where('collegeId', isEqualTo: collegeName).get();
    
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (DocumentSnapshot doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await fetchEquipments(); // Refresh the list after deletion
  }

  /// Generates the next 7-digit equipment ID for a college.
  /// First 3 digits are the college code.
  /// Last 4 digits are sequential.
  String generateNextEquipmentId(String collegeCode) {
    // Filter equipments that belong to this college and have a 7-digit numeric ID starting with collegeCode
    final collegeEquipments = _equipments.where((e) => 
      e.id.length == 7 && 
      e.id.startsWith(collegeCode) && 
      int.tryParse(e.id) != null
    ).toList();

    if (collegeEquipments.isEmpty) {
      return '${collegeCode}0001';
    }

    // Find the maximum sequential number
    int maxSeq = 0;
    for (var e in collegeEquipments) {
      final seqPart = e.id.substring(3);
      final seq = int.tryParse(seqPart) ?? 0;
      if (seq > maxSeq) {
        maxSeq = seq;
      }
    }

    final nextSeq = maxSeq + 1;
    return collegeCode + nextSeq.toString().padLeft(4, '0');
  }

  /// Automatically assigns an HOD to all equipments in their department and college.
  Future<void> assignHODToDepartmentEquipments(String collegeId, String department, String hodId) async {
    final QuerySnapshot snapshot = await _equipmentCollection
        .where('collegeId', isEqualTo: collegeId)
        .where('department', isEqualTo: department)
        .get();

    final WriteBatch batch = FirebaseFirestore.instance.batch();
    bool updated = false;
    for (DocumentSnapshot doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final assignedIds = List<String>.from(data['assignedEmployeeIds'] ?? []);
      if (!assignedIds.contains(hodId)) {
        assignedIds.add(hodId);
        batch.update(doc.reference, {'assignedEmployeeIds': assignedIds});
        updated = true;
      }
    }
    if (updated) {
      await batch.commit();
      await fetchEquipments();
    }
  }

  /// Automatically assigns an employee to ALL equipments in specified departments within their college.
  Future<void> assignEquipmentsToEmployee(String collegeId, List<String> departments, String employeeId) async {
    if (departments.isEmpty) return;

    // Fetch all equipments for this college in the specified departments
    final QuerySnapshot snapshot = await _equipmentCollection
        .where('collegeId', isEqualTo: collegeId)
        .where('department', whereIn: departments)
        .get();

    final WriteBatch batch = FirebaseFirestore.instance.batch();
    bool updated = false;

    for (DocumentSnapshot doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final assignedIds = List<String>.from(data['assignedEmployeeIds'] ?? []);
      if (!assignedIds.contains(employeeId)) {
        assignedIds.add(employeeId);
        batch.update(doc.reference, {'assignedEmployeeIds': assignedIds});
        updated = true;
      }
    }

    if (updated) {
      await batch.commit();
      await fetchEquipments();
    }
  }
}
