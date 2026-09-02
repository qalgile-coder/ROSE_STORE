import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/order_model.dart';

class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> {
  final _searchController = TextEditingController();
  OrderModel? _searchedOrder;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchOrder() async {
    final orderId = _searchController.text.trim();
    if (orderId.isEmpty) {
      setState(() => _searchedOrder = null);
      return;
    }

    setState(() => _isSearching = true);
    final order = await ref.read(adminServiceProvider).getOrderById(orderId);
    setState(() {
      _searchedOrder = order;
      _isSearching = false;
    });

    if (order == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOrdersAsync = ref.watch(allOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter Order ID...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send_rounded, color: colorScheme.primary, size: 20),
                    onPressed: _searchOrder,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _searchOrder(),
              ),
            ),
          ),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchedOrder != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OrderCard(order: _searchedOrder!),
            )
          else
            Expanded(
              child: allOrdersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders found.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _OrderCard(order: orders[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt),
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CUSTOMER', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(order.customerName, style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL AMOUNT', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('Rs ${order.totalAmount}', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface, fontSize: 16)),
                ],
              ),
            ],
          ),
          if (!isCancelled && order.status != OrderStatus.delivered) ...[
            const Divider(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CANCEL ORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('This action cannot be undone. Are you sure?'),
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

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = const Color(0xFFF59E0B); break;
      case OrderStatus.delivered: color = const Color(0xFF10B981); break;
      case OrderStatus.cancelled: color = const Color(0xFFEF4444); break;
      default: color = const Color(0xFF6366F1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
