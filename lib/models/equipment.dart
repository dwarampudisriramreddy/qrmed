import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  String id;
  String qrcode;
  String name;
  String group;
  String manufacturer;
  String type; // critical, non-critical
  String mode; // mercury, electrical, portable, hydrolic
  String serialNo;
  String department;
  DateTime installationDate;
  String status;
  String service; // active, non-active
  double purchasedCost;
  bool hasWarranty;
  DateTime? warrantyUpto;
  List<String>? assignedEmployeeIds; // Changed to List for multi-select
  String collegeId;

  Equipment({
    required this.id,
    required this.qrcode,
    required this.name,
    required this.group,
    required this.manufacturer,
    required this.type,
    required this.mode,
    required this.serialNo,
    required this.department,
    required this.installationDate,
    required this.status,
    required this.service,
    required this.purchasedCost,
    required this.hasWarranty,
    this.warrantyUpto,
    this.assignedEmployeeIds,
    required this.collegeId,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    // Normalize status by trimming whitespace to ensure consistent filtering
    String status = (json['status'] as String? ?? '').trim();
    
    List<String>? assignedIds;
    if (json['assignedEmployeeIds'] != null) {
      assignedIds = List<String>.from(json['assignedEmployeeIds']);
    } else if (json['assignedEmployeeId'] != null) {
      // Migration: support old single ID field
      assignedIds = [json['assignedEmployeeId'] as String];
    }

    return Equipment(
      id: json['id'] as String,
      qrcode: json['qrcode'] as String,
      name: json['name'] as String,
      group: json['group'] as String,
      manufacturer: json['manufacturer'] as String,
      type: json['type'] as String,
      mode: json['mode'] as String,
      serialNo: json['serialNo'] as String,
      department: json['department'] as String,
      installationDate: (json['installationDate'] as Timestamp).toDate(),
      status: status,
      service: json['service'] as String,
      purchasedCost: (json['purchasedCost'] as num).toDouble(),
      hasWarranty: json['hasWarranty'] as bool,
      warrantyUpto: json['warrantyUpto'] != null
          ? (json['warrantyUpto'] as Timestamp).toDate()
          : null,
      assignedEmployeeIds: assignedIds,
      collegeId: json['collegeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qrcode': qrcode,
      'name': name,
      'group': group,
      'manufacturer': manufacturer,
      'type': type,
      'mode': mode,
      'serialNo': serialNo,
      'department': department,
      'installationDate': Timestamp.fromDate(installationDate),
      'status': status,
      'service': service,
      'purchasedCost': purchasedCost,
      'hasWarranty': hasWarranty,
      'warrantyUpto': warrantyUpto != null ? Timestamp.fromDate(warrantyUpto!) : null,
      'assignedEmployeeIds': assignedEmployeeIds,
      'collegeId': collegeId,
    };
  }

  Equipment copyWith({
    String? id,
    String? qrcode,
    String? name,
    String? type,
    String? group,
    String? mode,
    String? manufacturer,
    String? serialNo,
    String? department,
    String? status,
    String? service,
    DateTime? warrantyUpto,
    double? purchasedCost,
    DateTime? installationDate,
    List<String>? assignedEmployeeIds,
    bool? hasWarranty,
    String? collegeId,
  }) {
    return Equipment(
      id: id ?? this.id,
      qrcode: qrcode ?? this.qrcode,
      name: name ?? this.name,
      type: type ?? this.type,
      group: group ?? this.group,
      mode: mode ?? this.mode,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNo: serialNo ?? this.serialNo,
      department: department ?? this.department,
      status: status ?? this.status,
      service: service ?? this.service,
      warrantyUpto: warrantyUpto ?? this.warrantyUpto,
      purchasedCost: purchasedCost ?? this.purchasedCost,
      installationDate: installationDate ?? this.installationDate,
      assignedEmployeeIds: assignedEmployeeIds ?? this.assignedEmployeeIds,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      collegeId: collegeId ?? this.collegeId,
    );
  }

  /// Returns true if the equipment is working, false otherwise
  /// Handles status normalization (trimming whitespace) for consistent checking
  bool get isWorking {
    return status.trim() == 'Working';
  }

  /// Returns true if the equipment is not working
  bool get isNotWorking {
    final normalizedStatus = status.trim();
    return normalizedStatus.isNotEmpty && normalizedStatus != 'Working';
  }

  // Helper for single ID backward compatibility if needed in UI
  String? get assignedEmployeeId => (assignedEmployeeIds != null && assignedEmployeeIds!.isNotEmpty) 
      ? assignedEmployeeIds!.first 
      : null;
}
