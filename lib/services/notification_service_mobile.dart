import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    print('NotificationService: Initializing...');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('NotificationService: Notification tapped! Response: ${response.payload}');
        },
      );
      print('NotificationService: Plugin initialized successfully');

      // Create a high-importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'qrmed_notifications',
        'QR Med Notifications',
        description: 'Notifications for equipment status changes',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        print('NotificationService: Creating Android notification channel...');
        await androidPlugin.createNotificationChannel(channel);
        print('NotificationService: Channel created');
        
        // Request permissions for Android 13+
        print('NotificationService: Requesting Android 13+ permissions...');
        final granted = await androidPlugin.requestNotificationsPermission();
        print('NotificationService: Permission granted: $granted');
      }
    } catch (e) {
      print('NotificationService Error during initialization: $e');
    }
  }

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  static bool get isSystemNotificationSupported => Platform.isAndroid || Platform.isIOS;
  
  static bool get isSystemNotificationEnabled => true; // Mobile plugin handles its own suppression if permission is missing

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('NotificationService: Attempting to show notification (ID: $id, Title: $title)');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'qrmed_notifications',
      'QR Med Notifications',
      channelDescription: 'Notifications for equipment status changes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''), // Support for longer messages
      category: AndroidNotificationCategory.message,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'plain',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      print('NotificationService: Notification shown successfully');
    } catch (e) {
      print('NotificationService Error showing notification: $e');
    }
  }
}
