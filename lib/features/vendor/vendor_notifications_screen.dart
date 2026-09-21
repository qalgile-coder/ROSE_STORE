import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/vendor_notification_model.dart';
import '../../theme/app_colors.dart';

class VendorNotificationsScreen extends ConsumerWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final notificationsAsync = ref.watch(vendorNotificationsProvider);
    final user = ref.watch(userModelProvider).asData?.value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vendor Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.05), shape: BoxShape.circle),
                    child: Icon(Icons.notifications_none_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
                  ),
                  const SizedBox(height: 24),
                  Text('No alerts yet', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('We\'ll notify you about orders and stock.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _VendorNotificationCard(
              notification: notifications[index],
              vendorId: user?.uid ?? '',
              colorScheme: colorScheme,
              isLight: isLight,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _VendorNotificationCard extends ConsumerWidget {
  final VendorNotificationModel notification;
  final String vendorId;
  final ColorScheme colorScheme;
  final bool isLight;
  const _VendorNotificationCard({required this.notification, required this.vendorId, required this.colorScheme, required this.isLight});

  IconData _getIcon() {
    switch (notification.type) {
      case VendorNotificationType.newOrder: return Icons.shopping_bag_rounded;
      case VendorNotificationType.orderCancelled: return Icons.cancel_schedule_send_rounded;
      case VendorNotificationType.newReview: return Icons.forum_rounded;
      case VendorNotificationType.lowStock: return Icons.warning_amber_rounded;
      case VendorNotificationType.shopApproved: return Icons.verified_user_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case VendorNotificationType.newOrder: return AppColors.success;
      case VendorNotificationType.orderCancelled: return AppColors.error;
      case VendorNotificationType.newReview: return Colors.purple;
      case VendorNotificationType.lowStock: return AppColors.warning;
      case VendorNotificationType.shopApproved: return Colors.blue;
      default: return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(vendorServiceProvider).deleteNotification(vendorId, notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            ref.read(vendorServiceProvider).markAsRead(vendorId, notification.id);
          }
        },
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notification.isRead ? colorScheme.surface : colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: notification.isRead ? colorScheme.outline.withOpacity(0.1) : colorScheme.primary.withOpacity(0.2)
            ),
            boxShadow: isLight && notification.isRead ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(), color: _getColor(), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(notification.timestamp),
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
