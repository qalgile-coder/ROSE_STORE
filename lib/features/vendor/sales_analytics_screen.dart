import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';

class VendorSalesAnalyticsScreen extends ConsumerWidget {
  const VendorSalesAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Sales Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
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
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.4),
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'DAILY'),
              Tab(text: 'WEEKLY'),
              Tab(text: 'MONTHLY'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SalesTabContent(period: 'Daily'),
            _SalesTabContent(period: 'Weekly'),
            _SalesTabContent(period: 'Monthly'),
          ],
        ),
      ),
    );
  }
}

class _SalesTabContent extends ConsumerWidget {
  final String period;
  const _SalesTabContent({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final analyticsAsync = ref.watch(vendorSalesAnalyticsProvider(period));

    return analyticsAsync.when(
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No sales data available'));

        final double revenue = (data['revenue'] ?? 0.0).toDouble();
        final int orders = (data['orders'] ?? 0) as int;
        final int itemsSold = (data['itemsSold'] ?? 0) as int;
        final double avgValue = (data['avgValue'] ?? 0.0).toDouble();
        final topProducts = (data['topProducts'] ?? []) as List<dynamic>;
        final chartMap = (data['chartMap'] ?? {}) as Map<int, double>;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'PERFORMANCE SUMMARY', color: colorScheme.primary),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1, // Adjusted for more height to prevent overflow
                children: [
                  _AnalyticsStatCard(
                    title: 'Revenue', 
                    value: 'Rs ${_formatCurrency(revenue)}', 
                    icon: Icons.payments_rounded, 
                    color: AppColors.success, 
                    colorScheme: colorScheme, 
                    isLight: isLight
                  ),
                  _AnalyticsStatCard(
                    title: 'Orders', 
                    value: orders.toString(), 
                    icon: Icons.shopping_bag_rounded, 
                    color: AppColors.info, 
                    colorScheme: colorScheme, 
                    isLight: isLight
                  ),
                  _AnalyticsStatCard(
                    title: 'Items Sold', 
                    value: itemsSold.toString(), 
                    icon: Icons.inventory_2_rounded, 
                    color: Colors.orange, 
                    colorScheme: colorScheme, 
                    isLight: isLight
                  ),
                  _AnalyticsStatCard(
                    title: 'Avg Value', 
                    value: 'Rs ${avgValue.toInt()}', 
                    icon: Icons.insights_rounded, 
                    color: Colors.purple, 
                    colorScheme: colorScheme, 
                    isLight: isLight
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              _SectionHeader(title: 'REVENUE TREND', color: colorScheme.primary),
              const SizedBox(height: 16),
              
              Container(
                height: 280,
                padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: isLight ? 0.3 : 0.05)),
                  boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)] : null,
                ),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: colorScheme.surface,
                        getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                          'Rs ${s.y.toStringAsFixed(1)}k',
                          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
                        )).toList(),
                      ),
                    ),
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
                          reservedSize: 30,
                          interval: _getChartInterval(period),
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_getBottomTitle(v, period), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (v, meta) => Text('${v.toStringAsFixed(1)}k', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateSpots(chartMap, period),
                        isCurved: true,
                        color: colorScheme.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true, 
                          gradient: LinearGradient(
                            colors: [colorScheme.primary.withValues(alpha: 0.2), colorScheme.primary.withValues(alpha: 0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              _SectionHeader(title: 'BEST SELLING PRODUCTS', color: colorScheme.primary),
              const SizedBox(height: 16),
              if (topProducts.isEmpty)
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 20),
                   child: Center(child: Text('No specific product data yet', style: TextStyle(fontSize: 12, color: Colors.grey))),
                 )
              else
                ...topProducts.map((p) => _TopProductTile(
                  name: p['name'], 
                  sales: '${p['sales']} sales', 
                  revenue: 'Rs ${p['revenue'].toInt()}', 
                  colorScheme: colorScheme, 
                  isLight: isLight
                )),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  double _getChartInterval(String period) {
    if (period == 'Daily') return 4;
    if (period == 'Weekly') return 1;
    return 5;
  }

  String _getBottomTitle(double v, String period) {
    if (period == 'Daily') return '${v.toInt()}h';
    if (period == 'Weekly') {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      int idx = v.toInt() - 1;
      if (idx >= 0 && idx < 7) return days[idx];
    }
    return '${v.toInt()}';
  }

  List<FlSpot> _generateSpots(Map<int, double> chartMap, String period) {
    List<FlSpot> spots = [];
    int max = period == 'Daily' ? 23 : (period == 'Weekly' ? 7 : 31);
    int min = period == 'Weekly' ? 1 : 0;
    
    for (int i = min; i <= max; i++) {
      spots.add(FlSpot(i.toDouble(), (chartMap[i] ?? 0.0) / 1000.0));
    }
    // Sort spots by x
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 2))]);
}

class _AnalyticsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  final bool isLight;

  const _AnalyticsStatCard({required this.title, required this.value, required this.icon, required this.color, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: isLight ? 0.3 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Use spaceBetween instead of Spacer to avoid Column overflow
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
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
              Text(title.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final String name;
  final String sales;
  final String revenue;
  final ColorScheme colorScheme;
  final bool isLight;

  const _TopProductTile({required this.name, required this.sales, required this.revenue, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: isLight ? 0.3 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.inventory_2_rounded, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(sales.toUpperCase(), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
          Text(revenue, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 14)),
        ],
      ),
    );
  }
}
