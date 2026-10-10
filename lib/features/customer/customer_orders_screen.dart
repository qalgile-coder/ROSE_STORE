import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import './widgets/customer_bottom_nav.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['ONGOING', 'HISTORY', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderStatus> _getStatusListForTab(int index) {
    switch (index) {
      case 0: return [
        OrderStatus.pending, 
        OrderStatus.confirmed, 
        OrderStatus.accepted, 
        OrderStatus.preparing, 
        OrderStatus.reachedVendor, 
        OrderStatus.pickedUp, 
        OrderStatus.outForDelivery
      ];
      case 1: return [OrderStatus.delivered];
      case 2: return [OrderStatus.cancelled, OrderStatus.rejected];
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;
    final dividerColor = isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('order_history'.tr(ref), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: secondaryTextColor,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: List.generate(_tabs.length, (index) {
          return ordersAsync.when(
            data: (orders) {
              final statusList = _getStatusListForTab(index);
              final filtered = orders.where((o) => statusList.contains(o.status)).toList();

              if (filtered.isEmpty) {
                return _EmptyOrdersState(label: _tabs[index], cardColor: cardColor, secondaryTextColor: secondaryTextColor, textColor: textColor);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: filtered.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, itemIndex) {
                  final order = filtered[itemIndex];
                  final bool canDelete = index > 0; // index is the Tab index (1: HISTORY, 2: CANCELLED)

                  if (canDelete) {
                    return Dismissible(
                      key: Key(order.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        ref.read(customerServiceProvider).deleteOrderForCustomer(order.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Order removed from history'),
                            backgroundColor: cardColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 28),
                      ),
                      child: _OrderCard(
                        order: order,
                        isLight: isLight,
                        cardColor: cardColor,
                        primaryColor: primaryColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        dividerColor: dividerColor,
                      ),
                    );
                  }

                  return _OrderCard(
                    order: order,
                    isLight: isLight,
                    cardColor: cardColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    dividerColor: dividerColor,
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
            error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
          );
        }),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  final String label;
  final Color cardColor;
  final Color secondaryTextColor;
  final Color textColor;
  const _EmptyOrdersState({required this.label, required this.cardColor, required this.secondaryTextColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 48, color: secondaryTextColor.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text('No ${label.toLowerCase()} orders', style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Place your first order to start tracking', style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isLight;
  final Color cardColor;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color dividerColor;

  const _OrderCard({
    required this.order, 
    required this.isLight, 
    required this.cardColor, 
    required this.primaryColor, 
    required this.textColor, 
    required this.secondaryTextColor, 
    required this.dividerColor
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/order-details/${order.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isLight ? Border.all(color: dividerColor) : Border.all(color: dividerColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: order.shopImageUrl.isNotEmpty
                        ? Image.network(order.shopImageUrl, fit: BoxFit.cover)
                        : Icon(Icons.storefront_rounded, color: primaryColor, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shopName, 
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor, letterSpacing: -0.2)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(color: secondaryTextColor.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(height: 1, color: dividerColor.withOpacity(isLight ? 1 : 0.2)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} ${order.items.length == 1 ? 'ITEM' : 'ITEMS'} • Rs ${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd • h:mm a').format(order.createdAt),
                      style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TRACK', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
    String label = status.name.toUpperCase();
    
    switch (status) {
      case OrderStatus.pending: color = AppColors.warning; break;
      case OrderStatus.confirmed:
      case OrderStatus.accepted: color = AppColors.info; break;
      case OrderStatus.preparing: color = Colors.indigoAccent; break;
      case OrderStatus.outForDelivery:
      case OrderStatus.pickedUp: 
        color = Colors.purpleAccent; 
        label = status == OrderStatus.outForDelivery ? 'ON THE WAY' : 'PICKED UP';
        break;
      case OrderStatus.delivered: color = AppColors.success; break;
      default: color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
