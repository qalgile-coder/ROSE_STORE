import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/notification_model.dart';
import '../../theme/app_colors.dart';
import '../../core/localization.dart';

class CustomerNotificationsScreen extends ConsumerWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider).asData?.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    if (user == null) return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(customerServiceProvider).markAllNotificationsAsRead(user.uid),
            icon: Icon(Icons.done_all_rounded, color: colorScheme.primary, size: 22),
            tooltip: 'Mark all as read',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: ref.read(customerServiceProvider).getNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: colorScheme.error)));
          
          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text('no_notifications'.tr(ref), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            itemCount: notifications.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.startToEnd,
                onDismissed: (direction) {
                  ref.read(customerServiceProvider).deleteNotification(user.uid, notif.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification removed'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: colorScheme.primary,
                        onPressed: () {
                          // In a real app, you might want to re-insert it, 
                          // but for simplicity we'll just show the message.
                        },
                      ),
                    ),
                  );
                },
                background: Container(
                  padding: const EdgeInsets.only(left: 20),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.delete_sweep_rounded, color: colorScheme.error, size: 28),
                ),
                child: _NotificationTile(
                  notif: notif,
                  colorScheme: colorScheme,
                  isLight: isLight,
                  onTap: () {
                    if (!notif.isRead) {
                      ref.read(customerServiceProvider).markNotificationAsRead(user.uid, notif.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final ColorScheme colorScheme;
  final bool isLight;
  final VoidCallback? onTap;
  const _NotificationTile({required this.notif, required this.colorScheme, required this.isLight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notif.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? colorScheme.surface.withOpacity(0.5) : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isRead ? null : Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1),
          boxShadow: isLight && !isRead ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)] : null,
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRead ? (isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground) : colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(notif.type), 
              color: isRead ? colorScheme.onSurface.withOpacity(0.3) : colorScheme.primary, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 15, 
                    color: isRead ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurface
                  )
                ),
                const SizedBox(height: 6),
                Text(
                  notif.message, 
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5), 
                    fontSize: 13, 
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  )
                ),
                const SizedBox(height: 10),
                Text(
                  DateFormat('MMM dd • h:mm a').format(notif.timestamp),
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8, 
              height: 8, 
              decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)
            ),
        ],
      ),
    ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderStatus: return Icons.shopping_bag_rounded;
      case NotificationType.offer: return Icons.local_offer_rounded;
      case NotificationType.supportTicket: return Icons.forum_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}
