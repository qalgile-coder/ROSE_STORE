import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import './widgets/vendor_bottom_nav.dart';

class VendorDashboard extends ConsumerWidget {
  const VendorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _VendorHero(ref: ref),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: const _VendorKpiGrid(),
                ),
                const _ShopStatusCard(),
                const SizedBox(height: 32),
                const _ManageShop(),
                const SizedBox(height: 32),
                const _IncomingOrders(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 0),
    );
  }
}

class _VendorHero extends ConsumerWidget {
  final WidgetRef ref;
  const _VendorHero({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final shopAsync = ref.watch(currentShopProvider);
    final user = ref.watch(userModelProvider).asData?.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
      decoration: BoxDecoration(
        color: isLight ? colorScheme.primary : AppColors.premiumDarkBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isLight ? Colors.white : colorScheme.primary).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VENDOR PORTAL',
                          style: TextStyle(
                            color: (isLight ? Colors.white : colorScheme.primary).withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shopAsync.value?.name ?? 'Loading Shop...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _HeaderActionIcon(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => context.push('/vendor/notifications'),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/vendor/profile'),
                        child: Hero(
                          tag: 'vendor_profile',
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: isLight ? Colors.white24 : colorScheme.surface,
                              backgroundImage: (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
                                  ? NetworkImage(user.profilePicture!)
                                  : null,
                              child: (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                                  ? Text(
                                      user?.name.substring(0, 1).toUpperCase() ?? 'V',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              InkWell(
                onTap: () => context.push('/vendor/earnings'),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Revenue",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              'Rs ${NumberFormat('#,###').format(user?.totalEarnings ?? 0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Real-time',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _VendorKpiGrid extends ConsumerWidget {
  const _VendorKpiGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingOrders = ref.watch(incomingOrdersProvider).asData?.value ?? [];
    final totalItems = ref.watch(shopProductsProvider).asData?.value ?? [];
    final lowStockItems = totalItems.where((p) => p.stock < 5).length;
    final shop = ref.watch(currentShopProvider).asData?.value;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _KpiCard(
          title: 'Pending',
          value: incomingOrders.length.toString(),
          icon: Icons.pending_actions_rounded,
          color: AppColors.warning,
          onTap: () => context.push('/vendor/orders'),
        ),
        _KpiCard(
          title: 'Inventory',
          value: totalItems.length.toString(),
          icon: Icons.inventory_2_rounded,
          color: AppColors.info,
          onTap: () => context.push('/vendor/products'),
        ),
        _KpiCard(
          title: 'Low Stock',
          value: lowStockItems.toString(),
          icon: Icons.auto_graph_rounded,
          color: AppColors.error,
          onTap: () => context.push('/vendor/low-stock'),
        ),
        _KpiCard(
          title: 'Rating',
          value: shop?.rating.toStringAsFixed(1) ?? '0.0',
          icon: Icons.star_rounded,
          color: Colors.orange,
          onTap: () => context.push('/vendor/reviews'),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isLight ? 0.1 : 0.05)),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
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

class _ShopStatusCard extends ConsumerWidget {
  const _ShopStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopAsync = ref.watch(currentShopProvider);

    return shopAsync.when(
      data: (shop) {
        if (shop == null) return const SizedBox.shrink();
        final bool isOnline = shop.status == 'active';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isOnline 
                ? AppColors.success.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isOnline ? AppColors.success.withValues(alpha: 0.2) : theme.colorScheme.outline.withValues(alpha: 0.1)
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOnline ? Icons.storefront_rounded : Icons.store_mall_directory_outlined,
                  color: isOnline ? AppColors.success : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? "STORE ONLINE" : "STORE CLOSED",
                      style: TextStyle(
                        color: isOnline ? AppColors.success : theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline 
                          ? 'Visible to all customers' 
                          : 'Currently hidden from search',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isOnline,
                activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                activeColor: AppColors.success,
                onChanged: (v) {
                  ref.read(vendorServiceProvider).updateShopStatus(
                    shop.id, 
                    v ? 'active' : 'disabled'
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        debugPrint('Shop Status Error: $e');
        return const SizedBox.shrink();
      },
    );
  }
}

class _ManageShop extends StatelessWidget {
  const _ManageShop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionItem(
              label: 'Add Product', 
              icon: Icons.add_rounded, 
              color: const Color(0xFF10B981),
              onTap: () => context.push('/vendor/add-product'),
            ),
            _ActionItem(
              label: 'Inventory', 
              icon: Icons.layers_rounded, 
              color: theme.colorScheme.primary, 
              onTap: () => context.push('/vendor/products'),
            ),
            _ActionItem(
              label: 'Coupons', 
              icon: Icons.confirmation_number_rounded, 
              color: const Color(0xFFF59E0B), 
              onTap: () => context.push('/vendor/coupons'),
            ),
            _ActionItem(
              label: 'Reviews', 
              icon: Icons.forum_rounded, 
              color: Colors.purple, 
              onTap: () => context.push('/vendor/reviews'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05)),
                boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))] : null,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingOrders extends ConsumerWidget {
  const _IncomingOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final incomingOrdersAsync = ref.watch(incomingOrdersProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ORDERS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              TextButton(
                onPressed: () => context.push('/vendor/orders'),
                child: Text('VIEW ALL', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          incomingOrdersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), size: 48),
                        const SizedBox(height: 16),
                        Text('Everything up to date!', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }
              final recentOrders = orders.take(3).toList();
              return Column(
                children: recentOrders.map((order) {
                  return Column(
                    children: [
                      _OrderTile(
                        order: order,
                        onTap: () => context.push('/vendor/order-details/${order.id}'),
                      ),
                      if (order != recentOrders.last) 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) {
              debugPrint('Vendor Dashboard Error: $e');
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      SizedBox(height: 16),
                      Text('Unable to load recent orders', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 52, width: 52,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, 5).toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.customerName} • Rs ${order.totalAmount.round()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${DateTime.now().difference(order.createdAt).inMinutes}m ago',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
