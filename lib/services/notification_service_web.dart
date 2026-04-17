// lib/services/notification_service_web.dart
import 'dart:html' as html;

class NotificationService {
  static Future<void> initialize() async {
    print('NotificationService (Web): Initializing...');
    try {
      if (!html.Notification.supported) {
        print('NotificationService (Web): Notifications are NOT supported by this browser.');
        return;
      }
      print('NotificationService (Web): Current permission status: ${html.Notification.permission}');
    } catch (e) {
      print('NotificationService (Web) Error during initialization: $e');
    }
  }

  static Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    final result = await html.Notification.requestPermission();
    return result == 'granted';
  }

  static bool get isSystemNotificationSupported => html.Notification.supported;
  
  static bool get isSystemNotificationEnabled => 
    html.Notification.supported && html.Notification.permission == 'granted';

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('NotificationService (Web): Attempting to show notification (ID: $id, Title: $title)');
    
    try {
      if (!html.Notification.supported) {
        print('NotificationService (Web): Notifications are NOT supported by this browser.');
        return;
      }

      final status = html.Notification.permission;
      print('NotificationService (Web): Permission status is $status');

      if (status == 'granted') {
        _createNotification(title, body);
      } else if (status != 'denied') {
        print('NotificationService (Web): Requesting permission...');
        final result = await html.Notification.requestPermission();
        print('NotificationService (Web): Permission request result: $result');
        if (result == 'granted') {
          _createNotification(title, body);
        }
      } else {
        print('NotificationService (Web): Permission denied.');
      }
    } catch (e) {
      print('NotificationService (Web) Error in showSystemNotification: $e');
    }
  }

  static void _createNotification(String title, String body) {
    try {
      print('NotificationService (Web): Creating notification object...');
      
      final notification = html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png',
        tag: 'qrmed-notification',
      );

      notification.onClick.listen((event) {
        print('NotificationService (Web): Notification clicked');
        notification.close();
      });
      
      print('NotificationService (Web): Notification triggered successfully');
    } catch (e) {
      print('NotificationService (Web) Error in _createNotification: $e');
    }
  }
}
