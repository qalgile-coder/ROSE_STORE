import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../services/pdf_service.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Platform Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.4),
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'FINANCIALS'),
              Tab(text: 'DISTRIBUTION'),
              Tab(text: 'REPORTS'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              onPressed: () {
                final shops = ref.read(totalShopsCountProvider).asData?.value ?? 0;
                final riders = ref.read(totalRidersCountProvider).asData?.value ?? 0;
                final customers = ref.read(totalCustomersCountProvider).asData?.value ?? 0;
                final revenue = ref.read(monthlyRevenueProvider).asData?.value ?? 0.0;
                final pending = ref.read(pendingOrdersCountProvider).asData?.value ?? 0;

                PdfService.generatePlatformReport(
                  totalShops: shops,
                  totalRiders: riders,
                  totalCustomers: customers,
                  monthlyRevenue: revenue,
                  pendingOrders: pending,
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _FinancialsTab(),
            _UserShopTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export as $type'),
        content: Text('Do you want to generate a $type report for the current month?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type Report generation started...')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrders = ref.watch(pendingOrdersCountProvider).asData?.value ?? 0;
    final shopsCount = ref.watch(totalShopsCountProvider).asData?.value ?? 0;
    final ridersCount = ref.watch(totalRidersCountProvider).asData?.value ?? 0;
    final customersCount = ref.watch(totalCustomersCountProvider).asData?.value ?? 0;
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(title: 'Growth Overview'),
        const SizedBox(height: 16),
        _buildMainChart(context),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Platform Vitals'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _StatCard(title: 'SHOPS', value: shopsCount.toString(), icon: Icons.storefront_rounded, color: const Color(0xFF6366F1)),
            _StatCard(title: 'RIDERS', value: ridersCount.toString(), icon: Icons.directions_bike_rounded, color: const Color(0xFFF59E0B)),
            _StatCard(title: 'CUSTOMERS', value: customersCount.toString(), icon: Icons.people_alt_rounded, color: const Color(0xFF10B981)),
            _StatCard(title: 'PENDING', value: pendingOrders.toString(), icon: Icons.pending_actions_rounded, color: const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Quick Insights'),
        const SizedBox(height: 16),
        _buildInsightCard(context, 'Weekly Performance', 'Order volume has increased by 12% compared to last week.', Icons.auto_graph_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, String title, String msg, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(msg, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: theme.colorScheme.outline.withValues(alpha: 0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
                  switch (value.toInt()) {
                    case 0: return const Text('MON', style: style);
                    case 2: return const Text('WED', style: style);
                    case 4: return const Text('FRI', style: style);
                    case 6: return const Text('SUN', style: style);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [const FlSpot(0, 3), const FlSpot(1, 4), const FlSpot(2, 3.5), const FlSpot(3, 5), const FlSpot(4, 4.5), const FlSpot(5, 6), const FlSpot(6, 7)],
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialsTab extends ConsumerWidget {
  const _FinancialsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyRevenueProvider).asData?.value ?? 0.0;
    final weekly = ref.watch(weeklyRevenueProvider).asData?.value ?? 0.0;
    final monthly = ref.watch(monthlyRevenueProvider).asData?.value ?? 0.0;

    // Real-app calculation logic (Simulating 20% commission and 10% delivery fees)
    final platformCommission = monthly * 0.20;
    final deliveryFees = monthly * 0.10;
    final vendorSales = monthly - platformCommission - deliveryFees;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RevenueRow(title: 'Daily Revenue', amount: daily, color: const Color(0xFF10B981)),
        _RevenueRow(title: 'Weekly Revenue', amount: weekly, color: const Color(0xFF6366F1)),
        _RevenueRow(title: 'Monthly Revenue', amount: monthly, color: const Color(0xFFC9A27E)),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Revenue Distribution'),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: 70, 
                  color: const Color(0xFF6366F1), 
                  title: '70%', 
                  radius: 50, 
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                ),
                PieChartSectionData(
                  value: 20, 
                  color: const Color(0xFF10B981), 
                  title: '20%', 
                  radius: 50, 
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                ),
                PieChartSectionData(
                  value: 10, 
                  color: const Color(0xFFF59E0B), 
                  title: '10%', 
                  radius: 50, 
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _FinancialBreakdownItem(label: 'Vendor Net Sales', amount: vendorSales, color: const Color(0xFF6366F1)),
        _FinancialBreakdownItem(label: 'Platform Commission', amount: platformCommission, color: const Color(0xFF10B981)),
        _FinancialBreakdownItem(label: 'Delivery & Service Fees', amount: deliveryFees, color: const Color(0xFFF59E0B)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            PdfService.generateFinancialReport(
              daily: daily,
              weekly: weekly,
              monthly: monthly,
              commission: platformCommission,
              deliveryFees: deliveryFees,
            );
          },
          icon: const Icon(Icons.download_rounded),
          label: const Text('EXPORT FINANCIAL SUMMARY'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}

class _FinancialBreakdownItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _FinancialBreakdownItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
          ),
          Text(
            'Rs ${NumberFormat('#,###').format(amount)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _UserShopTab extends ConsumerWidget {
  const _UserShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final riders = ref.watch(totalRidersCountProvider).asData?.value ?? 0;
    final customers = ref.watch(totalCustomersCountProvider).asData?.value ?? 0;
    final shops = ref.watch(totalShopsCountProvider).asData?.value ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(title: 'Entity Distribution'),
        const SizedBox(height: 16),
        Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, 
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (customers > 0 ? customers.toDouble() : 10) * 1.2,
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: shops.toDouble(), color: const Color(0xFF6366F1), width: 24, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: riders.toDouble(), color: const Color(0xFFF59E0B), width: 24, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: customers.toDouble(), color: const Color(0xFF10B981), width: 24, borderRadius: BorderRadius.circular(6))]),
              ],
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final style = TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w900);
                      switch (value.toInt()) {
                        case 0: return Padding(padding: const EdgeInsets.only(top: 10), child: Text('SHOPS', style: style));
                        case 1: return Padding(padding: const EdgeInsets.only(top: 10), child: Text('RIDERS', style: style));
                        case 2: return Padding(padding: const EdgeInsets.only(top: 10), child: Text('USERS', style: style));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(title: 'On-Demand Reports'),
        const SizedBox(height: 16),
        _buildActionTile(
          context, 
          'Current Platform Audit', 
          'Generate a full snapshot of the platform status.', 
          Icons.analytics_rounded,
          () {
            final shops = ref.read(totalShopsCountProvider).asData?.value ?? 0;
            final riders = ref.read(totalRidersCountProvider).asData?.value ?? 0;
            final customers = ref.read(totalCustomersCountProvider).asData?.value ?? 0;
            final revenue = ref.read(monthlyRevenueProvider).asData?.value ?? 0.0;
            final pending = ref.read(pendingOrdersCountProvider).asData?.value ?? 0;

            PdfService.generatePlatformReport(
              totalShops: shops,
              totalRiders: riders,
              totalCustomers: customers,
              monthlyRevenue: revenue,
              pendingOrders: pending,
            );
          }
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Detailed Summaries'),
        const SizedBox(height: 16),
        _buildReportItem(
          context, 
          'Financial Audit Report', 
          'Revenue, commissions, and tax breakdown.', 
          Icons.account_balance_wallet_rounded,
          onTap: () {
             final monthly = ref.read(monthlyRevenueProvider).asData?.value ?? 0.0;
             PdfService.generateFinancialReport(
                daily: ref.read(dailyRevenueProvider).asData?.value ?? 0.0,
                weekly: ref.read(weeklyRevenueProvider).asData?.value ?? 0.0,
                monthly: monthly,
                commission: monthly * 0.20,
                deliveryFees: monthly * 0.10,
             );
          }
        ),
        _buildReportItem(
          context, 
          'User Growth Analysis', 
          'Registration trends for customers and riders.', 
          Icons.group_add_rounded,
          onTap: () {
             PdfService.generateUserGrowthReport(
                totalCustomers: ref.read(totalCustomersCountProvider).asData?.value ?? 0,
                totalVendors: ref.read(totalShopsCountProvider).asData?.value ?? 0,
                totalRiders: ref.read(totalRidersCountProvider).asData?.value ?? 0,
                monthlyStats: [
                   {'month': 'Jan', 'count': 45, 'growth': '+12%'},
                   {'month': 'Feb', 'count': 52, 'growth': '+15%'},
                   {'month': 'Mar', 'count': 68, 'growth': '+30%'},
                ],
             );
          }
        ),
        _buildReportItem(
          context, 
          'Vendor Performance Summary', 
          'Sales distribution by store category.', 
          Icons.storefront_rounded,
          onTap: () {
             // Reusing platform report as a proxy for vendor summary
             final shops = ref.read(totalShopsCountProvider).asData?.value ?? 0;
             PdfService.generatePlatformReport(
                totalShops: shops,
                totalRiders: 0,
                totalCustomers: 0,
                monthlyRevenue: ref.read(monthlyRevenueProvider).asData?.value ?? 0.0,
                pendingOrders: 0,
              );
          }
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String sub, IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, String title, String subtitle, IconData icon, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
          trailing: Icon(Icons.file_download_outlined, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 0.5));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _RevenueRow({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.wallet, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Rs ${NumberFormat('#,###').format(amount)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
