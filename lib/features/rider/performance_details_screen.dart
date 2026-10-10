import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/order_model.dart';

class PerformanceDetailsScreen extends ConsumerWidget {
  const PerformanceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(userModelProvider).asData?.value;
    final history = ref.watch(riderHistoryProvider).asData?.value ?? [];

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final completedOrders = history.where((o) => o.status == OrderStatus.delivered).length;
    final totalAssigned = history.length;
    final completionRateNum = totalAssigned > 0 ? (completedOrders / totalAssigned * 100) : 0.0;
    final completionRate = completionRateNum.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Performance Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainScore(user.rating, completionRate, completionRateNum, colorScheme),
            const SizedBox(height: 32),
            _SectionTitle(title: 'KEY PERFORMANCE INDICATORS', color: colorScheme.primary),
            const SizedBox(height: 16),
            _buildStatsGrid(completionRate, colorScheme),
            const SizedBox(height: 40),
            _SectionTitle(title: 'DELIVERY TRENDS', color: colorScheme.primary),
            const SizedBox(height: 16),
            _buildPerformanceChart(colorScheme),
            const SizedBox(height: 40),
            _SectionTitle(title: 'DETAILED METRICS', color: colorScheme.primary),
            const SizedBox(height: 16),
            _buildMetricsList(totalAssigned, completedOrders, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScore(double rating, String completionRate, double rateNum, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: rateNum / 100,
                  strokeWidth: 10,
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05),
                  color: AppColors.success,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$completionRate%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text('RATE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expert Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.success, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Maintaining high completion rates unlocks priority delivery requests.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String completionRate, ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(label: 'COMPLETION', value: '$completionRate%', color: Colors.blue, colorScheme: colorScheme),
        _StatCard(label: 'ACCEPTANCE', value: '95.0%', color: Colors.purple, colorScheme: colorScheme),
        _StatCard(label: 'ON-TIME', value: '98.2%', color: AppColors.success, colorScheme: colorScheme),
        _StatCard(label: 'CANCELLATION', value: '0.8%', color: AppColors.error, colorScheme: colorScheme),
      ],
    );
  }

  Widget _buildPerformanceChart(ColorScheme colorScheme) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(1, 4.2),
                const FlSpot(2, 3.8),
                const FlSpot(3, 5),
                const FlSpot(4, 4.5),
                const FlSpot(5, 4.8),
              ],
              isCurved: true,
              color: AppColors.rider,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.rider.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsList(int total, int completed, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _MetricTile(label: 'Total Orders Assigned', value: total.toString(), icon: Icons.assignment_turned_in_rounded, colorScheme: colorScheme),
          _MetricTile(label: 'Orders Completed', value: completed.toString(), icon: Icons.local_shipping_rounded, colorScheme: colorScheme),
          _MetricTile(label: 'Customer Compliments', value: (completed ~/ 4).toString(), icon: Icons.favorite_rounded, colorScheme: colorScheme),
          _MetricTile(label: 'Average Delivery Time', value: '22m', icon: Icons.timer_rounded, colorScheme: colorScheme, isLast: true),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 2))]);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;
  const _StatCard({required this.label, required this.value, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color))),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool isLast;
  const _MetricTile({required this.label, required this.value, required this.icon, required this.colorScheme, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 18),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
        ],
      ),
    );
  }
}
