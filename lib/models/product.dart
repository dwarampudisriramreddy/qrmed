class Product {
  String id; // PROD-001
  String equipmentName;
  String equipmentType;
  String equipmentGroup;
  String deviceType;
  String manufacturer;
  String serialNo;
  String department;
  String status;
  String serviceStatus;
  DateTime? warranty;
  double? purchasedValue;
  DateTime? purchasedDate;
  String? employeeAssigned;
  DateTime? verifiedDate;
  String? verifiedBy;
  String collegeId; // Which college owns this product

  Product({
    required this.id,
    required this.equipmentName,
    required this.equipmentType,
    required this.equipmentGroup,
    required this.deviceType,
    required this.manufacturer,
    required this.serialNo,
    required this.department,
    required this.status,
    required this.serviceStatus,
    this.warranty,
    this.purchasedValue,
    this.purchasedDate,
    this.employeeAssigned,
    this.verifiedDate,
    this.verifiedBy,
    required this.collegeId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      equipmentName: json['equipmentName'] as String,
      equipmentType: json['equipmentType'] as String,
      equipmentGroup: json['equipmentGroup'] as String,
      deviceType: json['deviceType'] as String,
      manufacturer: json['manufacturer'] as String,
      serialNo: json['serialNo'] as String,
      department: json['department'] as String,
      status: json['status'] as String,
      serviceStatus: json['serviceStatus'] as String,
      warranty: json['warranty'] != null ? DateTime.tryParse(json['warranty']) : null,
      purchasedValue: (json['purchasedValue'] as num?)?.toDouble(),
      purchasedDate: json['purchasedDate'] != null ? DateTime.tryParse(json['purchasedDate']) : null,
      employeeAssigned: json['employeeAssigned'] as String?,
      verifiedDate: json['verifiedDate'] != null ? DateTime.tryParse(json['verifiedDate']) : null,
      verifiedBy: json['verifiedBy'] as String?,
      collegeId: json['collegeId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentName': equipmentName,
      'equipmentType': equipmentType,
      'equipmentGroup': equipmentGroup,
      'deviceType': deviceType,
      'manufacturer': manufacturer,
      'serialNo': serialNo,
      'department': department,
      'status': status,
      'serviceStatus': serviceStatus,
      'warranty': warranty?.toIso8601String(),
      'purchasedValue': purchasedValue,
      'purchasedDate': purchasedDate?.toIso8601String(),
      'employeeAssigned': employeeAssigned,
      'verifiedDate': verifiedDate?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'collegeId': collegeId,
    };
  }
}
