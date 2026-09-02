import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/activity_model.dart';
import '../../theme/app_colors.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ModernHeader(ref: ref),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _KpiGrid(),
                    const SizedBox(height: 32),
                    const _AdminQuickActions(),
                    const SizedBox(height: 32),
                    const _PlatformPulse(),
                    const SizedBox(height: 32),
                    const _ActivityFeed(),
                    const SizedBox(height: 140),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: const _FloatingAdminNav(),
          ),
        ],
      ),
    );
  }
}

class _ModernHeader extends StatelessWidget {
  final WidgetRef ref;
  const _ModernHeader({required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            theme.scaffoldBackgroundColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PLATFORM MASTER',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zen Mart Pro',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              _TopBarActions(),
            ],
          ),
          const SizedBox(height: 48),
          _RevenueMasterCard(ref: ref),
        ],
      ),
    );
  }
}

class _TopBarActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider).asData?.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _ModernCircleAction(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push('/admin/notifications'),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => context.push('/admin/profile'),
          child: Hero(
            tag: 'admin_avatar',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.surface,
                backgroundImage: (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                    ? Text(user?.name.substring(0, 1).toUpperCase() ?? 'A', style: const TextStyle(fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernCircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ModernCircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: colorScheme.onSurface, size: 22),
      ),
    );
  }
}

class _RevenueMasterCard extends StatelessWidget {
  final WidgetRef ref;
  const _RevenueMasterCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dailyAsync = ref.watch(dailyRevenueProvider);
    final weeklyAsync = ref.watch(weeklyRevenueProvider);
    final monthlyAsync = ref.watch(monthlyRevenueProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Revenue', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w700, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Text('18.2%', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          monthlyAsync.when(
            data: (val) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Rs ${NumberFormat('#,###').format(val)}',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1.5),
              ),
            ),
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_,__) => const Text('Rs 0.00'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _RevenueMiniStat(
                label: 'Today', 
                value: dailyAsync.when(data: (v) => 'Rs ${NumberFormat.compact().format(v)}', loading: () => '...', error: (_,__) => 'Rs 0'), 
                color: const Color(0xFF6366F1)
              ),
              const SizedBox(width: 32),
              _RevenueMiniStat(
                label: 'This Week', 
                value: weeklyAsync.when(data: (v) => 'Rs ${NumberFormat.compact().format(v)}', loading: () => '...', error: (_,__) => 'Rs 0'), 
                color: const Color(0xFF8B5CF6)
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueMiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RevenueMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _ModernKpi(
          title: 'Payouts',
          value: ref.watch(pendingPayoutsCountProvider).asData?.value.toString() ?? '0',
          icon: Icons.payments_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => context.push('/admin/payouts'),
        ),
        _ModernKpi(
          title: 'Riders',
          value: ref.watch(totalRidersCountProvider).asData?.value.toString() ?? '0',
          icon: Icons.directions_bike_rounded,
          color: const Color(0xFF38BDF8),
          onTap: () => context.push('/admin/users?tab=2'),
        ),
        _ModernKpi(
          title: 'Pending',
          value: ref.watch(pendingOrdersCountProvider).asData?.value.toString() ?? '0',
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFEF4444),
          onTap: () => context.push('/admin/pending-orders'),
        ),
        _ModernKpi(
          title: 'Shops',
          value: ref.watch(totalShopsCountProvider).asData?.value.toString() ?? '0',
          icon: Icons.storefront_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push('/admin/users?tab=0'),
        ),
      ],
    );
  }
}

class _ModernKpi extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernKpi({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced from 16 to 12
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced from 10 to 8
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 18), // Reduced from 20 to 18
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: colorScheme.onSurface.withValues(alpha: 0.1)),
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -1)
                      ),
                    ),
                    Text(
                      title.toUpperCase(), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminQuickActions extends StatelessWidget {
  const _AdminQuickActions();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Administrative Command', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _ModernToolCard(label: 'Map', icon: Icons.map_rounded, color: const Color(0xFFC9A27E), route: '/admin/order-map'),
              _ModernToolCard(label: 'Orders', icon: Icons.receipt_long_rounded, color: const Color(0xFF6366F1), route: '/admin/orders'),
              _ModernToolCard(label: 'Inventory', icon: Icons.inventory_2_rounded, color: const Color(0xFF10B981), route: '/admin/shops'),
              _ModernToolCard(label: 'Users', icon: Icons.people_rounded, color: const Color(0xFF38BDF8), route: '/admin/users'),
              _ModernToolCard(label: 'Support', icon: Icons.support_agent_rounded, color: const Color(0xFFF59E0B), route: '/admin/support'),
              _ModernToolCard(label: 'Finances', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF8B5CF6), route: '/admin/analytics'),
              _ModernToolCard(label: 'Settings', icon: Icons.settings_rounded, color: Colors.grey, route: '/admin/system'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernToolCard extends StatelessWidget {
  final String label, route;
  final IconData icon;
  final Color color;
  const _ModernToolCard({required this.label, required this.icon, required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: 78, height: 78,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _PlatformPulse extends StatelessWidget {
  const _PlatformPulse();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Pulse', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text('System monitoring active. 4 nodes operational.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.primary),
        ],
      ),
    );
  }
}

class _ActivityFeed extends ConsumerWidget {
  const _ActivityFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activityAsync = ref.watch(activityLogsProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Real-time Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            TextButton(
              onPressed: () => context.push('/admin/activity-log'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: activityAsync.when(
            data: (logs) => logs.isEmpty 
              ? const Center(child: Text('Scanning for activity...'))
              : Column(children: logs.take(5).map((l) => _ModernActivityItem(log: l, isLast: l == logs.take(5).last)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,__) => Text('Error: $e'),
          ),
        ),
      ],
    );
  }
}

class _ModernActivityItem extends StatelessWidget {
  final ActivityModel log;
  final bool isLast;
  const _ModernActivityItem({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10, height: 10,
                decoration: BoxDecoration(color: log.color, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 2)),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1, color: colorScheme.outline.withValues(alpha: 0.1))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Text(
                        _formatTime(log.timestamp),
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.subtitle,
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _FloatingAdminNav extends StatelessWidget {
  const _FloatingAdminNav();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AdminNavIcon(icon: Icons.dashboard_rounded, label: 'Hub', isActive: true, onTap: () {}),
                _AdminNavIcon(icon: Icons.storefront_rounded, label: 'Stores', onTap: () => context.push('/admin/shops')),
                _AdminNavIcon(icon: Icons.people_rounded, label: 'Users', onTap: () => context.push('/admin/users')),
                _AdminNavIcon(icon: Icons.analytics_rounded, label: 'Data', onTap: () => context.push('/admin/analytics')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _AdminNavIcon({required this.icon, required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
