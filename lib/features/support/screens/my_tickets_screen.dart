import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../models/support_ticket_model.dart';
import '../../../services/support_service.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider).asData?.value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final bgColor = isLight ? AppColors.lightBackground : AppColors.supportDarkBackground;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.supportDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.supportDarkTextSecondary;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.supportDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.supportDarkSurface;
    final dividerColor = isLight ? AppColors.lightBorder : AppColors.supportDarkDivider;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('My Support Tickets', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<SupportTicketModel>>(
        stream: ref.watch(supportServiceProvider).getUserTickets(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.confirmation_number_outlined, size: 64, color: primaryColor.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No Tickets Yet', 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'When you have an issue, create a ticket and it will appear here for tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryTextColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => context.push('/support/create-ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('CREATE NEW TICKET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketCard(
                ticket: ticket,
                isLight: isLight,
                cardColor: cardColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                divider: dividerColor,
                primary: primaryColor,
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  final bool isLight;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color divider;
  final Color primary;

  const _TicketCard({
    required this.ticket,
    required this.isLight,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.divider,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: divider),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)] : null,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TICKET #${ticket.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        letterSpacing: 1,
                      ),
                    ),
                    _StatusChip(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondaryTextColor, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: divider),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MetaItem(icon: Icons.category_outlined, label: ticket.category, color: secondaryTextColor),
                    const SizedBox(width: 16),
                    _MetaItem(icon: Icons.calendar_today_rounded, label: DateFormat('MMM dd').format(ticket.createdAt), color: secondaryTextColor),
                    const Spacer(),
                    if (ticket.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '${ticket.unreadCount} NEW',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: secondaryTextColor.withOpacity(0.3)),
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TicketStatus.open: color = AppColors.info; break;
      case TicketStatus.resolved: color = AppColors.success; break;
      case TicketStatus.closed: color = AppColors.textDisabled; break;
      default: color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
