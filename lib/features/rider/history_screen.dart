import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';

class RiderHistoryScreen extends ConsumerStatefulWidget {
  const RiderHistoryScreen({super.key});

  @override
  ConsumerState<RiderHistoryScreen> createState() => _RiderHistoryScreenState();
}

class _RiderHistoryScreenState extends ConsumerState<RiderHistoryScreen> {
  String _filter = 'Today';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final historyAsync = ref.watch(riderHistoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Delivery History', style: TextStyle(fontWeight: FontWeight.w900)),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _FilterChip(label: 'Today', isSelected: _filter == 'Today', onSelected: () => setState(() => _filter = 'Today')),
                _FilterChip(label: 'Week', isSelected: _filter == 'Week', onSelected: () => setState(() => _filter = 'Week')),
                _FilterChip(label: 'Month', isSelected: _filter == 'Month', onSelected: () => setState(() => _filter = 'Month')),
                _FilterChip(label: 'All', isSelected: _filter == 'All', onSelected: () => setState(() => _filter = 'All')),
              ],
            ),
          ),
        ),
      ),
      body: historyAsync.when(
        data: (orders) {
          final filteredOrders = _applyFilter(orders);
          
          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                  const SizedBox(height: 16),
                  Text('No deliveries found for $_filter', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _HistoryTile(order: filteredOrders[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    final now = DateTime.now();
    switch (_filter) {
      case 'Today':
        return orders.where((o) => o.deliveredAt != null && 
          o.deliveredAt!.year == now.year && o.deliveredAt!.month == now.month && o.deliveredAt!.day == now.day).toList();
      case 'Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return orders.where((o) => o.deliveredAt != null && o.deliveredAt!.isAfter(weekAgo)).toList();
      case 'Month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return orders.where((o) => o.deliveredAt != null && o.deliveredAt!.isAfter(monthAgo)).toList();
      default:
        return orders;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.rider : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? Colors.transparent : colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final OrderModel order;
  const _HistoryTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isCancelled = order.status == OrderStatus.cancelled || order.status == OrderStatus.rejected;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isCancelled ? AppColors.error : AppColors.success).withValues(alpha: 0.1), 
                  shape: BoxShape.circle
                ),
                child: Icon(
                  isCancelled ? Icons.close_rounded : Icons.check_rounded, 
                  color: isCancelled ? AppColors.error : AppColors.success, 
                  size: 18
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}', 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.shopName} → ${order.customerName}',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${order.deliveryFee.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 16,
                      color: isCancelled ? colorScheme.onSurface.withValues(alpha: 0.2) : AppColors.success
                    ),
                  ),
                  Text(
                    'EARNING',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.2), letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.05)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 6),
                  Text(
                    order.deliveredAt != null 
                        ? DateFormat('MMM dd • h:mm a').format(order.deliveredAt!) 
                        : DateFormat('MMM dd • h:mm a').format(order.createdAt),
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCancelled ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCancelled ? 'CANCELLED' : 'COMPLETED',
                  style: TextStyle(
                    color: isCancelled ? AppColors.error : AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
