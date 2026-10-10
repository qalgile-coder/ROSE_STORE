import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/rider_notification_model.dart';
import '../../theme/app_colors.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notificationsAsync = ref.watch(riderNotificationsProvider);
    final user = ref.watch(userModelProvider).asData?.value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/rider');
            }
          },
        ),
        actions: [
          if (notificationsAsync.asData?.value.isNotEmpty ?? false)
            TextButton(
              onPressed: () {
                // Logic to mark all as read
              },
              child: const Text('MARK ALL READ', style: TextStyle(color: AppColors.rider, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                colorScheme: colorScheme,
                onDelete: () => ref.read(riderServiceProvider).deleteNotification(user!.uid, notification.id),
                onTap: () {
                  ref.read(riderServiceProvider).markAsRead(user!.uid, notification.id);
                  if (notification.data?['orderId'] != null) {
                    context.push('/rider/order-details/${notification.data!['orderId']}');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final RiderNotificationModel notification;
  final ColorScheme colorScheme;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.colorScheme,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notification.isRead ? colorScheme.surface : AppColors.rider.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.isRead ? colorScheme.outline.withValues(alpha: 0.05) : AppColors.rider.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                        fontSize: 15,
                        color: notification.isRead ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message, 
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500, height: 1.4)
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 10, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd • h:mm a').format(notification.timestamp),
                          style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.2), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(color: AppColors.rider, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(RiderNotificationType type) {
    switch (type) {
      case RiderNotificationType.newRequest: return Icons.delivery_dining_rounded;
      case RiderNotificationType.deliveryCancelled: return Icons.cancel_presentation_rounded;
      case RiderNotificationType.assignmentUpdated: return Icons.update_rounded;
      case RiderNotificationType.paymentReceived: return Icons.account_balance_wallet_rounded;
      case RiderNotificationType.bonusEarned: return Icons.stars_rounded;
      case RiderNotificationType.systemAnnouncement: return Icons.campaign_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  Color _getIconColor(RiderNotificationType type) {
    switch (type) {
      case RiderNotificationType.deliveryCancelled: return AppColors.error;
      case RiderNotificationType.paymentReceived:
      case RiderNotificationType.bonusEarned: return AppColors.success;
      case RiderNotificationType.newRequest: return AppColors.rider;
      default: return Colors.blue;
    }
  }
}
