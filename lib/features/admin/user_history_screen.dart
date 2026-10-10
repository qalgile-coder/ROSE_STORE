import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../models/payout_model.dart';

class UserHistoryScreen extends ConsumerWidget {
  final String userId;
  final UserRole role;
  const UserHistoryScreen({super.key, required this.userId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('${role.name.toUpperCase()} History', style: const TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ORDERS'),
              Tab(text: 'PAYOUTS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersList(userId: userId, role: role),
            _PayoutsList(userId: userId),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final String userId;
  final UserRole role;
  const _OrdersList({required this.userId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider); // In real app, use filtered provider

    return ordersAsync.when(
      data: (allOrders) {
        final orders = allOrders.where((o) {
          if (role == UserRole.customer) return o.customerId == userId;
          if (role == UserRole.vendor) return o.vendorId == userId;
          if (role == UserRole.rider) return o.riderId == userId;
          return false;
        }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('No order history found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rs ${order.totalAmount}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status.name),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _PayoutsList extends ConsumerWidget {
  final String userId;
  const _PayoutsList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutRequestsProvider);

    return payoutsAsync.when(
      data: (allPayouts) {
        final payouts = allPayouts.where((p) => p.userId == userId).toList();

        if (payouts.isEmpty) {
          return const Center(child: Text('No payout history found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: payouts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final payout = payouts[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.payments_rounded, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rs ${payout.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('MMM dd, yyyy').format(payout.createdAt), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  _StatusChip(status: payout.status.name),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'paid':
        color = Colors.green; break;
      case 'pending':
        color = Colors.orange; break;
      case 'cancelled':
      case 'rejected':
        color = Colors.red; break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}
