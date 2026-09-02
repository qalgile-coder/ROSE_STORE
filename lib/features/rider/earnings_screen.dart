import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../models/payout_model.dart';
import '../../services/pdf_service.dart';

class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(userModelProvider).asData?.value;
    final todayHistoryAsync = ref.watch(todayRiderHistoryProvider);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Earnings & Payouts", style: TextStyle(fontWeight: FontWeight.w900)),
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
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: colorScheme.primary),
            onPressed: () {
              final history = ref.read(riderHistoryProvider).asData?.value ?? [];
              PdfService.generateRiderEarningsReport(user, history);
            },
            tooltip: 'Export Statement',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EarningHero(user: user),
            const SizedBox(height: 40),
            
            _SectionTitle(title: 'STATISTICS', color: colorScheme.primary),
            const SizedBox(height: 16),
            _EarningsGrid(user: user, colorScheme: colorScheme),
            
            const SizedBox(height: 40),
            _SectionTitle(title: 'WITHDRAWAL HISTORY', color: colorScheme.primary),
            const SizedBox(height: 16),
            ref.watch(riderPayoutHistoryProvider).when(
              data: (payouts) => payouts.isEmpty 
                ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('No payouts requested yet.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)))))
                : Column(children: payouts.map((p) => _PayoutTile(payout: p, colorScheme: colorScheme)).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 40),
            _SectionTitle(title: "TODAY'S ACTIVITY", color: AppColors.success),
            const SizedBox(height: 16),
            todayHistoryAsync.when(
              data: (orders) => orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text('No activity today.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3))),
                      ),
                    )
                  : Column(children: orders.map((o) => _OrderEarningTile(order: o, colorScheme: colorScheme)).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _WithdrawalAction(balance: user.totalEarnings, user: user, theme: theme),
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

class _EarningHero extends StatelessWidget {
  final UserModel user;
  const _EarningHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: AppColors.rider.withValues(alpha: 0.1), blurRadius: 40)],
      ),
      child: Column(
        children: [
          Text("AVAILABLE BALANCE", style: TextStyle(color: AppColors.rider.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('Rs ${user.totalEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroStat(label: 'Total Tasks', value: user.totalDeliveries.toString()),
              Container(width: 1, height: 24, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 32)),
              _HeroStat(label: 'Avg. Rating', value: user.rating.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _EarningsGrid extends ConsumerWidget {
  final UserModel user;
  final ColorScheme colorScheme;
  const _EarningsGrid({required this.user, required this.colorScheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(riderHistoryProvider);

    return historyAsync.when(
      data: (orders) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfMonth = DateTime(now.year, now.month, 1);

        double daily = 0;
        double weekly = 0;
        double monthly = 0;

        for (var o in orders) {
          final date = o.deliveredAt ?? o.createdAt;
          if (date.day == now.day && date.month == now.month && date.year == now.year) {
            daily += o.deliveryFee;
          }
          if (date.isAfter(startOfWeek)) {
            weekly += o.deliveryFee;
          }
          if (date.isAfter(startOfMonth)) {
            monthly += o.deliveryFee;
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _StatCard(label: 'TODAY', value: 'Rs ${daily.toInt()}', color: Colors.blue),
            _StatCard(label: 'WEEKLY', value: 'Rs ${weekly.toInt()}', color: Colors.purple),
            _StatCard(label: 'MONTHLY', value: 'Rs ${monthly.toInt()}', color: Colors.orange),
            _StatCard(label: 'LIFETIME', value: 'Rs ${user.totalEarnings.toInt()}', color: AppColors.success),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _WithdrawalAction extends ConsumerStatefulWidget {
  final double balance;
  final UserModel user;
  final ThemeData theme;
  const _WithdrawalAction({required this.balance, required this.user, required this.theme});

  @override
  ConsumerState<_WithdrawalAction> createState() => _WithdrawalActionState();
}

class _WithdrawalActionState extends ConsumerState<_WithdrawalAction> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        border: Border(top: BorderSide(color: widget.theme.colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: ElevatedButton(
        onPressed: (widget.balance < 500 || _isRequesting) ? null : () => _showWithdrawalSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rider,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isRequesting 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('REQUEST PAYOUT', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  void _showWithdrawalSheet(BuildContext context) {
    final amountController = TextEditingController(text: widget.balance.toInt().toString());
    final hasBankDetails = widget.user.bankDetails != null && widget.user.bankDetails!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 28, right: 28, top: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payout Request', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Available Balance: Rs ${widget.balance.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              
              if (!hasBankDetails)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Colors.red, size: 32),
                      const SizedBox(height: 16),
                      const Text('Bank Account Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Please update your payout method in profile settings to enable withdrawals.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () { Navigator.pop(context); context.push('/rider/profile'); }, 
                        child: const Text('GO TO PROFILE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildField(label: 'Enter Amount', hint: '0', icon: Icons.payments_rounded, prefix: 'Rs ', controller: amountController),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [500, 1000, 2000, 5000].map((amt) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text('Rs $amt'),
                        selected: amountController.text == amt.toString(),
                        onSelected: (v) => setSheetState(() => amountController.text = amt.toString()),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: AppColors.rider,
                        labelStyle: TextStyle(color: amountController.text == amt.toString() ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.rider.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_rounded, color: AppColors.rider, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TRANSFER TO', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            Text(widget.user.bankDetails!['bankName'] ?? 'Verified Account', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(widget.user.bankDetails!['accountNumber'] ?? 'XXXX-XXXX', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount < 500) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is Rs 500')));
                      return;
                    }
                    if (amount > widget.balance) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient available balance')));
                       return;
                    }
                    
                    Navigator.pop(context);
                    setState(() => _isRequesting = true);
                    
                    try {
                      await ref.read(riderServiceProvider).requestWithdrawal(widget.user.uid, amount);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request sent to Zen Mart Admin!'), backgroundColor: AppColors.success));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    } finally {
                      if (mounted) setState(() => _isRequesting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rider,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const Text('CONFIRM WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required String hint, required IconData icon, String? prefix, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
            prefixIcon: Icon(icon, color: AppColors.rider, size: 20),
            prefixText: prefix,
            prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _OrderEarningTile extends StatelessWidget {
  final dynamic order;
  final ColorScheme colorScheme;
  const _OrderEarningTile({required this.order, required this.colorScheme});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.id.substring(0, 5).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 2),
              Text('${DateFormat('h:mm a').format(order.deliveredAt ?? DateTime.now())} • ${order.shopName}', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          Text('+Rs ${order.deliveryFee.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 16)),
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final PayoutModel payout;
  final ColorScheme colorScheme;
  const _PayoutTile({required this.payout, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (payout.status) {
      case PayoutStatus.paid:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case PayoutStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.timer_rounded;
        break;
      case PayoutStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout.status == PayoutStatus.paid ? 'Withdrawal Completed' : 
                  payout.status == PayoutStatus.pending ? 'Payout Processing' : 'Payout Rejected',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(payout.createdAt),
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11),
                ),
              ],
            ),
          ),
          Text('Rs ${payout.amount.toInt()}', style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 15)),
        ],
      ),
    );
  }
}
