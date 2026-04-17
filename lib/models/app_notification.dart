import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String targetUserId; // 'admin' or collegeId
  final bool isRead;
  final String? equipmentId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.targetUserId,
    this.isRead = false,
    this.equipmentId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      targetUserId: json['targetUserId'] as String,
      isRead: json['isRead'] as bool? ?? false,
      equipmentId: json['equipmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'targetUserId': targetUserId,
      'isRead': isRead,
      'equipmentId': equipmentId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? targetUserId,
    bool? isRead,
    String? equipmentId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      targetUserId: targetUserId ?? this.targetUserId,
      isRead: isRead ?? this.isRead,
      equipmentId: equipmentId ?? this.equipmentId,
    );
  }
}
