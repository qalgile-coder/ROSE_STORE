import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';

class RevenueAnalyticsScreen extends ConsumerWidget {
  const RevenueAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyRevenueProvider);
    final weeklyAsync = ref.watch(weeklyRevenueProvider);
    final monthlyAsync = ref.watch(monthlyRevenueProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Revenue Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Grid
            Row(
              children: [
                Expanded(
                  child: _RevenueStatCard(
                    title: 'TODAY',
                    amount: dailyAsync.asData?.value ?? 0.0,
                    color: const Color(0xFF10B981),
                    isLoading: dailyAsync.isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RevenueStatCard(
                    title: 'THIS WEEK',
                    amount: weeklyAsync.asData?.value ?? 0.0,
                    color: const Color(0xFF6366F1),
                    isLoading: weeklyAsync.isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RevenueStatCard(
              title: 'THIS MONTH',
              amount: monthlyAsync.asData?.value ?? 0.0,
              color: const Color(0xFFC9A27E),
              isLarge: true,
              isLoading: monthlyAsync.isLoading,
            ),
            
            const SizedBox(height: 32),
            Text('Revenue Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            
            // Chart Container
            Container(
              height: 300,
              padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(color: colorScheme.outline.withValues(alpha: 0.05), strokeWidth: 1),
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
                            case 0: return const Text('WK 1', style: style);
                            case 3: return const Text('WK 2', style: style);
                            case 6: return const Text('WK 3', style: style);
                            case 9: return const Text('WK 4', style: style);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3000),
                        const FlSpot(2, 4500),
                        const FlSpot(4, 3800),
                        const FlSpot(6, 6200),
                        const FlSpot(8, 5100),
                        const FlSpot(10, 7800),
                        const FlSpot(12, 6900),
                      ],
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Financial Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            
            _BreakdownTile(title: 'Gross Merchandise Value', amount: monthlyAsync.asData?.value ?? 0, icon: Icons.shopping_bag_rounded, color: const Color(0xFF6366F1)),
            _BreakdownTile(title: 'Net Platform Earnings', amount: (monthlyAsync.asData?.value ?? 0) * 0.15, icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF10B981)),
            _BreakdownTile(title: 'Processing Surcharges', amount: (monthlyAsync.asData?.value ?? 0) * 0.05, icon: Icons.receipt_long_rounded, color: const Color(0xFFF59E0B)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _RevenueStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final bool isLarge;
  final bool isLoading;

  const _RevenueStatCard({
    required this.title,
    required this.amount,
    required this.color,
    this.isLarge = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(height: 4),
          isLoading 
            ? const SizedBox(height: 28, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                'Rs ${NumberFormat.compact().format(amount)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLarge ? 28 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ],
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _BreakdownTile({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface)),
                Text('Real-time sync enabled', style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text(
            'Rs ${NumberFormat('#,###').format(amount)}',
            style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
