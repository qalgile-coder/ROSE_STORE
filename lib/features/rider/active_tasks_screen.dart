import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';

class ActiveTasksScreen extends ConsumerWidget {
  const ActiveTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeOrdersAsync = ref.watch(activeRiderOrdersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Active Deliveries', style: TextStyle(fontWeight: FontWeight.w900)),
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
      ),
      body: activeOrdersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bike_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                  const SizedBox(height: 16),
                  Text('No active tasks at the moment.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) => _ActiveTaskCard(order: orders[index], ref: ref, colorScheme: colorScheme),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final OrderModel order;
  final WidgetRef ref;
  final ColorScheme colorScheme;
  const _ActiveTaskCard({required this.order, required this.ref, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER #${order.id.substring(0, 8).toUpperCase()}', 
                style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 13, letterSpacing: 0.5)
              ),
              _StatusChip(status: order.status),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.05)),
          ),
          _AddressRow(label: 'PICKUP', name: order.shopName, address: order.pickupAddress, icon: Icons.storefront_rounded, colorScheme: colorScheme),
          const SizedBox(height: 20),
          _AddressRow(label: 'DELIVERY', name: order.customerName, address: order.deliveryAddress, icon: Icons.location_on_rounded, colorScheme: colorScheme),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.near_me_rounded, 
                  label: 'Navigate', 
                  color: Colors.blue,
                  onTap: () => launchUrl(Uri.parse('google.navigation:q=${order.deliveryAddress}')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_rounded, 
                  label: 'Chat',
                  onTap: () => context.push('/chat/${order.id}/${order.customerName}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_rounded, 
                  label: 'Call',
                  onTap: () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _NextStepButton(order: order, ref: ref),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.rider.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: AppColors.rider, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String label;
  final String name;
  final String address;
  final IconData icon;
  final ColorScheme colorScheme;

  const _AddressRow({required this.label, required this.name, required this.address, required this.icon, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(address, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.rider;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(), 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: accent, letterSpacing: 0.5)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepButton extends StatelessWidget {
  final OrderModel order;
  final WidgetRef ref;
  const _NextStepButton({required this.order, required this.ref});

  @override
  Widget build(BuildContext context) {
    String text = 'Next Step';
    OrderStatus next;
    
    if (order.status == OrderStatus.accepted) {
      text = 'I HAVE REACHED VENDOR';
      next = OrderStatus.reachedVendor;
    } else if (order.status == OrderStatus.reachedVendor) {
      text = 'I HAVE PICKED UP ORDER';
      next = OrderStatus.pickedUp;
    } else if (order.status == OrderStatus.pickedUp) {
      text = 'OUT FOR DELIVERY';
      next = OrderStatus.outForDelivery;
    } else if (order.status == OrderStatus.outForDelivery) {
      text = 'MARK AS DELIVERED';
      next = OrderStatus.delivered;
    } else {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (next == OrderStatus.delivered) {
            context.push('/rider/order-details/${order.id}');
          } else {
            ref.read(orderServiceProvider).updateStatus(order.id, next);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rider,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
