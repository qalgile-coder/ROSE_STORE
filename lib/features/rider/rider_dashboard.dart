import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import './widgets/rider_bottom_nav.dart';

class RiderDashboard extends ConsumerWidget {
  const RiderDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userAsync = ref.watch(userModelProvider);
    final todayHistoryAsync = ref.watch(todayRiderHistoryProvider);
    final activeOrdersAsync = ref.watch(activeRiderOrdersProvider);
    final availableOrdersAsync = ref.watch(availableOrdersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _RiderHero(user: user, ref: ref),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: _RiderKpiGrid(
                        user: user, 
                        activeOrdersCount: activeOrdersAsync.asData?.value.length ?? 0,
                        todayOrdersCount: todayHistoryAsync.asData?.value.length ?? 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Active Delivery Section
                    activeOrdersAsync.when(
                      data: (orders) => orders.isNotEmpty 
                          ? _ActiveDeliverySummary(order: orders.first)
                          : const SizedBox.shrink(),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 32),
                    const _QuickActions(),
                    const SizedBox(height: 32),
                    
                    // Available Orders Section
                    const _AvailableOrdersHeader(),
                    const SizedBox(height: 16),
                    if (!user.isOnline)
                      _OfflineOverlay()
                    else
                      availableOrdersAsync.when(
                        data: (orders) {
                          if (orders.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(Icons.radar_rounded, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                                    const SizedBox(height: 16),
                                    Text('No available requests nearby', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: orders.map((o) => _OrderRequestTile(order: o, riderId: user.uid)).toList(),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Error: $e'),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: const RiderBottomNav(currentIndex: 0),
    );
  }
}

class _RiderHero extends StatelessWidget {
  final UserModel user;
  final WidgetRef ref;

  const _RiderHero({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
      decoration: BoxDecoration(
        color: AppColors.premiumDarkBackground,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.rider.withValues(alpha: 0.15)),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                        style: TextStyle(color: user.isOnline ? AppColors.success : AppColors.rider.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text('Hello, ${user.name}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ],
                  ),
                  Row(
                    children: [
                      Switch.adaptive(
                        value: user.isOnline,
                        onChanged: (v) => ref.read(riderServiceProvider).toggleOnlineStatus(user.uid, v),
                        activeColor: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/rider/profile'),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.rider.withValues(alpha: 0.3), width: 2)),
                          child: CircleAvatar(
                            radius: 18, 
                            backgroundColor: colorScheme.surface, 
                            backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty) 
                                ? NetworkImage(user.profilePicture!) 
                                : null,
                            child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                                ? Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              InkWell(
                onTap: () => context.push('/rider/earnings'),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Earnings", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: ref.watch(todayRiderHistoryProvider).when(
                            data: (orders) {
                              final todayEarnings = orders.fold(0.0, (sum, order) => sum + order.deliveryFee);
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomLeft,
                                child: Text('Rs ${todayEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                              );
                            },
                            loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            error: (e, s) => const Text('Rs 0', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                          child: const Text('Bonus Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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

class _RiderKpiGrid extends StatelessWidget {
  final UserModel user;
  final int activeOrdersCount;
  final int todayOrdersCount;

  const _RiderKpiGrid({required this.user, required this.activeOrdersCount, required this.todayOrdersCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _KpiCard(
          title: 'Active Tasks',
          value: activeOrdersCount.toString().padLeft(2, '0'),
          icon: Icons.directions_bike_rounded,
          color: colorScheme.primary,
          onTap: () => context.push('/rider/active-tasks'),
        ),
        _KpiCard(
          title: 'Deliveries',
          value: todayOrdersCount.toString().padLeft(2, '0'),
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF10B981),
          onTap: () => context.push('/rider/history'),
        ),
        _KpiCard(
          title: 'Total Balance',
          value: 'Rs ${user.totalEarnings.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.rider,
          onTap: () => context.push('/rider/earnings'),
        ),
        _KpiCard(
          title: 'Rider Rating',
          value: user.rating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => context.push('/rider/reviews'),
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
  final VoidCallback onTap;

  const _KpiCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6), 
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
              child: Icon(icon, color: color, size: 16)
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value, 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title.toUpperCase(), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w800, letterSpacing: 0.5)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveDeliverySummary extends StatelessWidget {
  final OrderModel order;
  const _ActiveDeliverySummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.rider, AppColors.rider.withValues(alpha: 0.7)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.rider.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE DELIVERY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), 
                child: Text(order.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(order.shopName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(order.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/rider/order-details/${order.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: AppColors.rider, 
              minimumSize: const Size(double.infinity, 56), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('MANAGE TASK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _OfflineOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(32), 
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05))
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text('You are currently offline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Go online to receive new delivery requests nearby.', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('QUICK ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1.5)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionItem(label: 'History', icon: Icons.history_rounded, color: const Color(0xFF6366F1), onTap: () => context.push('/rider/history')),
            _ActionItem(label: 'Earnings', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF10B981), onTap: () => context.push('/rider/earnings')),
            _ActionItem(label: 'Tasks', icon: Icons.assignment_rounded, color: const Color(0xFFF59E0B), onTap: () => context.push('/rider/active-tasks')),
            _ActionItem(label: 'Support', icon: Icons.support_agent_rounded, color: AppColors.rider, onTap: () => context.push('/rider/support')),
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
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: 68, height: 68, 
              decoration: BoxDecoration(
                color: colorScheme.surface, 
                borderRadius: BorderRadius.circular(22), 
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
              ), 
              child: Icon(icon, color: color, size: 28)
            ), 
            const SizedBox(height: 10), 
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center)
          ]
        )
      )
    );
  }
}

class _AvailableOrdersHeader extends StatelessWidget {
  const _AvailableOrdersHeader();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text('AVAILABLE REQUESTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1.5)), 
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
          decoration: BoxDecoration(color: AppColors.rider.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), 
          child: const Text('LIVE', style: TextStyle(color: AppColors.rider, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))
        )
      ]
    );
  }
}

class _OrderRequestTile extends ConsumerWidget {
  final OrderModel order;
  final String riderId;
  const _OrderRequestTile({required this.order, required this.riderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(32), 
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.rider.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.shopping_bag_rounded, color: AppColors.rider, size: 22)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2)), 
                    const SizedBox(height: 4), 
                    Text(order.shopName, style: const TextStyle(color: AppColors.rider, fontWeight: FontWeight.w800, fontSize: 13)),
                  ]
                )
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, 
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Rs ${order.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.success))
                  ),
                  Text('EARNINGS', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1))
                ]
              ),
            ],
          ),
          const SizedBox(height: 24),
          _LocationInfo(icon: Icons.storefront_rounded, address: order.pickupAddress, label: 'PICKUP'),
          const SizedBox(height: 12),
          _LocationInfo(icon: Icons.location_on_rounded, address: order.deliveryAddress, label: 'DELIVERY'),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Payment: ', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600)),
              Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const Spacer(),
              Icon(Icons.near_me_rounded, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text('2.4 km', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ref.read(riderServiceProvider).rejectOrder(order.id, riderId), 
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6), 
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  minimumSize: const Size(0, 56)
                ), 
                child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
              )
            ), 
            const SizedBox(width: 12), 
            Expanded(
              flex: 2, 
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(orderServiceProvider).updateStatus(order.id, OrderStatus.accepted, riderId: riderId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order accepted successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to accept order: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rider, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  minimumSize: const Size(0, 56), 
                  elevation: 0
                ), 
                child: const Text('ACCEPT DELIVERY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
              )
            )
          ]),
        ],
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final IconData icon;
  final String address;
  final String label;
  const _LocationInfo({required this.icon, required this.address, required this.label});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
