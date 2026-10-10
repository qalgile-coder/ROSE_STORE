import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import './widgets/vendor_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _tabLabels = [
    'Pending',
    'Accepted',
    'Preparing',
    'Ready',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(vendorActiveOrderTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  OrderStatus? _getStatusForTab(int index) {
    switch (index) {
      case 0: return OrderStatus.pending;
      case 1: return OrderStatus.accepted;
      case 2: return OrderStatus.preparing;
      case 3: return OrderStatus.confirmed;
      case 4: return OrderStatus.delivered;
      case 5: return OrderStatus.cancelled;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final ordersAsync = ref.watch(allShopOrdersProvider);
    
    // Auto-sync tab controller with provider
    ref.listen(vendorActiveOrderTabProvider, (prev, next) {
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
                    boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)] : null,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search order ID or name...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.4),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: List.generate(_tabLabels.length, (index) {
          return ordersAsync.when(
            data: (orders) {
              final tabStatus = _getStatusForTab(index);
              final filtered = orders.where((order) {
                final matchesStatus = order.status == tabStatus;
                final matchesSearch = order.id.toLowerCase().contains(_searchQuery) || 
                                     order.customerName.toLowerCase().contains(_searchQuery);
                return matchesStatus && matchesSearch;
              }).toList();

              if (filtered.isEmpty) {
                return _EmptyState(label: _tabLabels[index]);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: filtered.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, itemIndex) => _OrderCard(
                  order: filtered[itemIndex],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        }),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 1),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text('No $label orders found', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600)),
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
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/vendor/order-details/${order.id}'),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: colorScheme.primary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd • h:mm a').format(order.createdAt),
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    _StatusBadge(status: order.status),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.person_rounded, color: colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          Text(
                            '${order.items.length} Items • Rs ${order.totalAmount.round()}',
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (order.status == OrderStatus.pending || order.status == OrderStatus.preparing)
                      _buildQuickAction(context, ref, colorScheme)
                    else
                      Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withOpacity(0.1), size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    String label = '';
    OrderStatus nextStatus = OrderStatus.pending;
    Color btnColor = colorScheme.primary;
    int nextTabIndex = 0;

    if (order.status == OrderStatus.pending) {
      label = 'ACCEPT';
      nextStatus = OrderStatus.preparing;
      btnColor = AppColors.success;
      nextTabIndex = 2; // Moving to Preparing tab
    } else if (order.status == OrderStatus.preparing) {
      label = 'PACK';
      nextStatus = OrderStatus.confirmed;
      btnColor = colorScheme.primary;
      nextTabIndex = 3; // Moving to Ready tab
    }

    return ElevatedButton(
      onPressed: () async {
        await ref.read(orderServiceProvider).updateStatus(order.id, nextStatus);
        ref.read(vendorActiveOrderTabProvider.notifier).state = nextTabIndex;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
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
      case OrderStatus.pending: color = AppColors.warning; break;
      case OrderStatus.preparing: color = AppColors.info; break;
      case OrderStatus.confirmed: color = AppColors.success; break;
      case OrderStatus.cancelled:
      case OrderStatus.rejected: color = AppColors.error; break;
      default: color = Colors.purple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
