// lib/services/notification_service_stub.dart

class NotificationService {
  static Future<void> initialize() async {}
  
  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  static Future<bool> requestPermission() async {
    return false;
  }

  static bool get isSystemNotificationSupported => false;
  static bool get isSystemNotificationEnabled => false;
}
