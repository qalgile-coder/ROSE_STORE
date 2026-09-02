import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../models/order_model.dart';

class PendingOrdersScreen extends ConsumerWidget {
  const PendingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allPendingOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pending Orders', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('No pending orders.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _OrderListTile(order: orders[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderListTile extends ConsumerWidget {
  final OrderModel order;
  const _OrderListTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: colorScheme.primary, letterSpacing: 0.5),
                ),
              ),
              Text(
                DateFormat('h:mm a').format(order.createdAt),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _OrderInfo(label: 'CUSTOMER', value: order.customerName, icon: Icons.person_rounded),
              _OrderInfo(label: 'STORE', value: order.shopName, icon: Icons.storefront_rounded),
            ],
          ),
          const Divider(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL AMOUNT', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    'Rs ${order.totalAmount}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: Icons.assignment_ind_rounded,
                label: 'Assign Rider',
                color: const Color(0xFFF59E0B),
                onTap: () => _showAssignRiderDialog(context, ref),
              ),
              _ActionButton(
                icon: Icons.cancel_rounded,
                label: 'Cancel Order',
                color: const Color(0xFFEF4444),
                onTap: () => _showCancelDialog(context, ref, order),
              ),
              _ActionButton(
                icon: Icons.call_rounded,
                label: 'Contact Store',
                onTap: () => launchUrl(Uri.parse('tel:${order.vendorPhone}')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignRiderDialog(BuildContext context, WidgetRef ref) {
    final ridersAsync = ref.watch(allRidersProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Rider'),
        content: ridersAsync.when(
          data: (riders) {
            final activeRiders = riders.where((r) => r.status == 'active' && r.isOnline).toList();
            if (activeRiders.isEmpty) return const Text('No online riders available right now.');
            
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeRiders.length,
                itemBuilder: (context, index) {
                  final rider = activeRiders[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(rider.name),
                    subtitle: Text(rider.vehicleInfo ?? 'No vehicle info'),
                    onTap: () async {
                      await ref.read(adminServiceProvider).assignRiderToOrder(order.id, rider.uid, rider.name);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order assigned to ${rider.name}')));
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('Error: $e'),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Text('Are you sure you want to cancel order #${order.id.substring(0, 8).toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('No')),
          TextButton(
            onPressed: () {
              ref.read(adminServiceProvider).cancelOrder(order.id);
              context.pop();
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _OrderInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OrderInfo({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
