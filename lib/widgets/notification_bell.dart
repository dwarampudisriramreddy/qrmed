import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/app_notification.dart';
import 'package:intl/intl.dart';

class NotificationBell extends StatelessWidget {
  final String targetUserId;

  const NotificationBell({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return StreamBuilder<List<AppNotification>>(
      stream: notificationProvider.getNotifications(targetUserId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => _showNotificationsDialog(context, notifications, notificationProvider),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context, List<AppNotification> initialNotifications, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<AppNotification>>(
        stream: provider.getNotifications(targetUserId),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? initialNotifications;

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications'),
                TextButton(
                  onPressed: () => provider.clearAll(targetUserId),
                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: notifications.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.message, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().add_jm().format(notification.timestamp),
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!notification.isRead) {
                              provider.markAsRead(notification.id);
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => provider.deleteNotification(notification.id),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
