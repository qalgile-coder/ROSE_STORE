import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../core/providers.dart';
import '../../models/user_model.dart';
import '../../models/support_ticket_model.dart';
import '../../services/support_service.dart';

class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Support Dashboard', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildStatsOverview(),
          _buildFilters(),
          Expanded(child: _buildTicketList()),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return StreamBuilder<List<SupportTicketModel>>(
      stream: ref.watch(supportServiceProvider).getAllTickets(),
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? [];
        final openCount = tickets.where((t) => t.status == TicketStatus.open).length;
        final resolvedToday = tickets.where((t) => t.status == TicketStatus.resolved && _isToday(t.updatedAt)).length;
        final highPriority = tickets.where((t) => t.priority == TicketPriority.high && t.status != TicketStatus.closed).length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              _StatCard(label: 'Open', count: openCount, color: Colors.blue),
              _StatCard(label: 'High Priority', count: highPriority, color: Colors.red),
              _StatCard(label: 'Resolved Today', count: resolvedToday, color: Colors.green),
              _StatCard(label: 'Total', count: tickets.length, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(label: 'All', isSelected: _selectedFilter == 'All', onTap: () => setState(() => _selectedFilter = 'All')),
          _FilterChip(label: 'Customer', isSelected: _selectedFilter == 'Customer', onTap: () => setState(() => _selectedFilter = 'Customer')),
          _FilterChip(label: 'Vendor', isSelected: _selectedFilter == 'Vendor', onTap: () => setState(() => _selectedFilter = 'Vendor')),
          _FilterChip(label: 'Rider', isSelected: _selectedFilter == 'Rider', onTap: () => setState(() => _selectedFilter = 'Rider')),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return StreamBuilder<List<SupportTicketModel>>(
      stream: ref.watch(supportServiceProvider).getAllTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var tickets = snapshot.data ?? [];

        // Apply filters
        if (_selectedFilter != 'All') {
          tickets = tickets.where((t) => t.userRole.name.toLowerCase() == _selectedFilter.toLowerCase()).toList();
        }

        if (tickets.isEmpty) {
          return const Center(child: Text('No tickets matching filters.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: tickets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return _AdminTicketCard(ticket: ticket);
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.4), 
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.1)),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _AdminTicketCard extends ConsumerWidget {
  final SupportTicketModel ticket;
  const _AdminTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isResolved = ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ticket.priority == TicketPriority.high ? const Color(0xFFEF4444).withValues(alpha: 0.2) : colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push('/support/ticket-chat/${ticket.id}'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(ticket.userRole).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.userRole.name.toUpperCase(),
                        style: TextStyle(
                          color: _getRoleColor(ticket.userRole),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (ticket.priority == TicketPriority.high)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.flash_on_rounded, color: Color(0xFFEF4444), size: 10),
                            SizedBox(width: 4),
                            Text('URGENT', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '#${ticket.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  ticket.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isResolved ? colorScheme.onSurface.withValues(alpha: 0.4) : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: ${ticket.userName}',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatusBadge(status: ticket.status),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ticket.category.toUpperCase(),
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (ticket.status == TicketStatus.open || ticket.status == TicketStatus.inProgress)
                      ElevatedButton(
                        onPressed: () {
                          ref.read(supportServiceProvider).updateTicketStatus(ticket.id, TicketStatus.resolved);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ticket marked as Resolved')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('RESOLVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(width: 6),
                    Text(
                      'Updated ${DateFormat('MMM d, h:mm a').format(ticket.updatedAt)}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.2), fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer: return const Color(0xFFC9A27E); // primary
      case UserRole.vendor: return const Color(0xFFD6B08A); // secondaryAccent
      case UserRole.rider: return const Color(0xFFD6B08A); // secondaryAccent
      default: return const Color(0xFFC9A27E); // primary
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TicketStatus.open: color = const Color(0xFF38BDF8); break;
      case TicketStatus.assigned: color = const Color(0xFF8B5CF6); break;
      case TicketStatus.inProgress: color = const Color(0xFFF59E0B); break;
      case TicketStatus.waitingForUser: color = const Color(0xFF06B6D4); break;
      case TicketStatus.resolved: color = const Color(0xFF10B981); break;
      case TicketStatus.closed: color = const Color(0xFF64748B); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
