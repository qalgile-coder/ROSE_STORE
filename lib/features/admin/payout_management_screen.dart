import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/payout_model.dart';
import '../../theme/app_colors.dart';

class PayoutManagementScreen extends ConsumerStatefulWidget {
  const PayoutManagementScreen({super.key});

  @override
  ConsumerState<PayoutManagementScreen> createState() => _PayoutManagementScreenState();
}

class _PayoutManagementScreenState extends ConsumerState<PayoutManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payout Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or amount...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, size: 20, color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.4),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'REQUESTS'),
                  Tab(text: 'HISTORY'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PayoutList(statusFilter: [PayoutStatus.pending, PayoutStatus.approved], searchQuery: _searchQuery),
          _PayoutList(statusFilter: [PayoutStatus.paid, PayoutStatus.rejected], searchQuery: _searchQuery),
        ],
      ),
    );
  }
}

class _PayoutList extends ConsumerWidget {
  final List<PayoutStatus> statusFilter;
  final String searchQuery;
  const _PayoutList({required this.statusFilter, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutRequestsProvider);

    return payoutsAsync.when(
      data: (allPayouts) {
        final filtered = allPayouts.where((p) {
          final matchesStatus = statusFilter.contains(p.status);
          final matchesSearch = p.userName.toLowerCase().contains(searchQuery) || 
                               p.amount.toString().contains(searchQuery);
          return matchesStatus && matchesSearch;
        }).toList();
        
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text('No payout records found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _PayoutListTile(payout: filtered[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _PayoutListTile extends ConsumerWidget {
  final PayoutModel payout;
  const _PayoutListTile({required this.payout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isPending = payout.status == PayoutStatus.pending;
    final bool isPaid = payout.status == PayoutStatus.paid;
    final bool isRejected = payout.status == PayoutStatus.rejected;

    final roleColor = payout.userType == PayoutUserType.vendor ? const Color(0xFF6366F1) : const Color(0xFFD6B08A);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  payout.userType == PayoutUserType.vendor ? Icons.storefront_rounded : Icons.directions_bike_rounded,
                  color: roleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payout.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(payout.userType.name.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2))),
                        const SizedBox(width: 8),
                        Text(DateFormat('MMM dd, hh:mm a').format(payout.createdAt), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${NumberFormat('#,###').format(payout.amount)}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isPaid ? const Color(0xFF10B981) : colorScheme.onSurface),
                  ),
                  if (!isPending)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payout.status.name.toUpperCase(),
                        style: TextStyle(color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (isPaid) ...[
            const Divider(height: 32),
            _buildPaidInfo(context),
          ],
          if (isPending) ...[
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectConfirmation(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showMarkPaidDialog(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), 
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('MARK PAID'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaidInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRANSACTION ID', style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            Text(payout.transactionId ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('PROCESSED ON', style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            Text(DateFormat('dd MMM yyyy').format(payout.processedAt ?? payout.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showRejectConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payout?'),
        content: Text('Are you sure you want to reject the payout of Rs ${payout.amount} to ${payout.userName}? The amount will be returned to their balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(adminServiceProvider).updatePayoutStatus(payout.id, PayoutStatus.rejected);
              Navigator.pop(context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMarkPaidDialog(BuildContext context, WidgetRef ref) {
    final methodController = TextEditingController(text: 'Bank Transfer');
    final txController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        title: Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TRANSFER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.05), 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Beneficiary', value: payout.userName),
                    const Divider(height: 24),
                    _InfoRow(label: 'Bank Name', value: payout.bankDetails?['bankName'] ?? 'Not set'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Account #', value: payout.bankDetails?['accountNumber'] ?? 'Not set'),
                    if (payout.bankDetails?['accountTitle'] != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Title', value: payout.bankDetails!['accountTitle']),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: methodController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: txController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'TX ID / Ref #', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('CANCEL', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () {
              if (txController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Transaction ID')));
                return;
              }
              ref.read(adminServiceProvider).updatePayoutStatus(
                payout.id, 
                PayoutStatus.paid, 
                txId: txController.text.trim(), 
                method: methodController.text.trim()
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), 
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('PROCESS'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
