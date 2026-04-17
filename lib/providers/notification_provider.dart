import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final CollectionReference _notificationCollection =
      FirebaseFirestore.instance.collection('notifications');
  
  StreamSubscription? _subscription;
  final Set<String> _seenNotificationIds = {};
  final _newNotificationController = StreamController<AppNotification>.broadcast();
  DateTime? _sessionStartTime;

  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;

  String? _currentTargetUserId;

  void startListening(String targetUserId) {
    if (_currentTargetUserId == targetUserId && _subscription != null) {
      print('DEBUG: NotificationProvider: Already listening for $targetUserId, skipping reset.');
      return;
    }
    
    print('DEBUG: NotificationProvider: Starting listener for targetUserId: $targetUserId');
    _currentTargetUserId = targetUserId;
    _sessionStartTime = DateTime.now();
    print('DEBUG: NotificationProvider: Session start time: $_sessionStartTime');
    
    _subscription?.cancel();
    _subscription = getNotifications(targetUserId).listen((notifications) {
      print('DEBUG: NotificationProvider: Received ${notifications.length} notifications from Firestore');
      if (notifications.isNotEmpty) {
        // Find all unread notifications we haven't seen in this session
        final unreadAndNew = notifications.where((n) {
          final isUnread = !n.isRead;
          final isNotSeen = !_seenNotificationIds.contains(n.id);
          // ONLY trigger system notification if it happened AFTER we started the session
          // Using a 1-minute buffer to handle potential clock drift between devices
          final isFromThisSession = _sessionStartTime != null && n.timestamp.isAfter(_sessionStartTime!.subtract(const Duration(minutes: 1)));
          
          if (isUnread && isNotSeen) {
            print('DEBUG: NotificationProvider: Checking notification: ${n.title}. isFromThisSession: $isFromThisSession, n.timestamp: ${n.timestamp}, sessionStartBuffer: ${_sessionStartTime?.subtract(const Duration(minutes: 1))}');
          }
          
          return isUnread && isNotSeen && isFromThisSession;
        }).toList();

        if (unreadAndNew.isNotEmpty) {
          print('DEBUG: NotificationProvider: Found ${unreadAndNew.length} new notifications to notify local system');
          
          for (var latest in unreadAndNew) {
            _seenNotificationIds.add(latest.id);
            
            print('DEBUG: NotificationProvider: Triggering showSystemNotification for ${latest.title}');
            NotificationService.showSystemNotification(
              id: latest.id.hashCode,
              title: latest.title,
              body: latest.message,
            );
            _newNotificationController.add(latest);
          }
        }
      }
      
      // Update seen IDs to only include current unread ones to prevent memory leak
      final currentUnreadIds = notifications.where((n) => !n.isRead).map((n) => n.id).toSet();
      _seenNotificationIds.retainAll(currentUnreadIds);
      
      // Still notify listeners for the bell icon badge count
      notifyListeners();
    }, onError: (error) {
      print('DEBUG ERROR: NotificationProvider listener error: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _newNotificationController.close();
    super.dispose();
  }

  Stream<List<AppNotification>> getNotifications(String targetUserId) {
    print('DEBUG: NotificationProvider: getNotifications stream requested for targetUserId: $targetUserId');
    return _notificationCollection
        .where('targetUserId', isEqualTo: targetUserId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotification.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          // Sort in memory to avoid needing composite indexes in Firestore
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          print('DEBUG: NotificationProvider: Stream for $targetUserId emitted ${notifications.length} notifications');
          return notifications;
        });
  }

  Future<void> addNotification(AppNotification notification) async {
    final docRef = _notificationCollection.doc();
    final newNotification = notification.copyWith(id: docRef.id);
    await docRef.set(newNotification.toJson());
    
    // Also trigger local notification immediately for the current user if they are the target
    if (_currentTargetUserId == newNotification.targetUserId) {
      print('DEBUG: NotificationProvider: Triggering immediate local notification for targetUserId: ${newNotification.targetUserId}');
      NotificationService.showSystemNotification(
        id: newNotification.id.hashCode,
        title: newNotification.title,
        body: newNotification.message,
      );
    } else {
      print('DEBUG: NotificationProvider: New notification target (${newNotification.targetUserId}) is NOT current user ($_currentTargetUserId)');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationCollection.doc(notificationId).update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationCollection.doc(notificationId).delete();
  }

  Future<void> clearAll(String targetUserId) async {
    final snapshot = await _notificationCollection
        .where('targetUserId', isEqualTo: targetUserId)
        .get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
