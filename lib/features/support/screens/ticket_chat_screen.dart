import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../models/user_model.dart';
import '../../../models/support_ticket_model.dart';
import '../../../services/support_service.dart';

class TicketChatScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketChatScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userModelProvider).asData?.value;
    if (user == null) return;

    _messageController.clear();

    final message = SupportMessageModel(
      id: '',
      senderId: user.uid,
      senderName: user.name,
      senderRole: user.role.name,
      message: text,
      timestamp: DateTime.now(),
    );

    await ref.read(supportServiceProvider).sendMessage(widget.ticketId, message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userModelProvider).asData?.value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final bgColor = isLight ? AppColors.lightBackground : AppColors.supportDarkBackground;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.supportDarkSurface;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.supportDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.supportDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.supportDarkTextSecondary;
    final dividerColor = isLight ? AppColors.lightBorder : AppColors.supportDarkDivider;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) return const Text('Support');
            final ticket = SupportTicketModel.fromFirestore(snapshot.data!);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title, 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'TICKET #${ticket.id.substring(0, 8).toUpperCase()}', 
                  style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.w700),
                ),
              ],
            );
          }
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: textColor),
            onPressed: () => _showTicketDetails(context, widget.ticketId, isLight, cardColor, textColor, secondaryTextColor, dividerColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('support_tickets').doc(widget.ticketId).snapshots(),
        builder: (context, ticketSnapshot) {
          final ticketData = ticketSnapshot.data?.data() as Map<String, dynamic>?;
          final isResolved = (ticketData?['status'] == 'resolved' || ticketData?['status'] == 'closed');

          return Column(
            children: [
              _buildStatusBanner(widget.ticketId, isLight, cardColor, textColor, secondaryTextColor, dividerColor),
              Expanded(
                child: StreamBuilder<List<SupportMessageModel>>(
                  stream: ref.watch(supportServiceProvider).getTicketMessages(widget.ticketId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == user.uid;
                        return _ChatBubble(
                          message: message, 
                          isMe: isMe,
                          primary: primaryColor,
                          cardColor: cardColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          isLight: isLight,
                        );
                      },
                    );
                  },
                ),
              ),
              if (!isResolved || user.role == UserRole.superAdmin)
                _buildInputArea(isLight, cardColor, textColor, secondaryTextColor, dividerColor, primaryColor)
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  width: double.infinity,
                  color: cardColor,
                  child: Text(
                    'This ticket has been resolved. You cannot send more messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(String ticketId, bool isLight, Color cardColor, Color textColor, Color secondaryTextColor, Color divider) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        final ticket = SupportTicketModel.fromFirestore(snapshot.data!);
        
        Color statusColor;
        switch (ticket.status) {
          case TicketStatus.open: statusColor = AppColors.info; break;
          case TicketStatus.resolved: statusColor = AppColors.success; break;
          case TicketStatus.closed: statusColor = AppColors.textDisabled; break;
          default: statusColor = AppColors.warning;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'STATUS: ${ticket.status.name.toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              if (ticket.status != TicketStatus.closed && ticket.status != TicketStatus.resolved)
                Text(
                  'Avg. reply: 2 min',
                  style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInputArea(bool isLight, Color cardColor, Color textColor, Color secondaryTextColor, Color divider, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: secondaryTextColor),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightSecondaryBackground : AppColors.supportDarkSecondaryBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(BuildContext context, String ticketId, bool isLight, Color cardColor, Color textColor, Color secondaryTextColor, Color divider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailsSheet(
        ticketId: ticketId,
        isLight: isLight,
        cardColor: cardColor,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        divider: divider,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final SupportMessageModel message;
  final bool isMe;
  final Color primary;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isLight;

  const _ChatBubble({
    required this.message, 
    required this.isMe, 
    required this.primary,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe 
        ? primary 
        : (isLight ? AppColors.lightSecondaryBackground : AppColors.supportDarkElevatedSurface);
    
    final bubbleTextColor = isMe ? Colors.white : textColor;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName, 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: secondaryTextColor.withOpacity(0.7))
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                if (isMe) BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                else if (isLight) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
              ],
            ),
            child: Text(
              message.message,
              style: TextStyle(color: bubbleTextColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(color: secondaryTextColor.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TicketDetailsSheet extends StatelessWidget {
  final String ticketId;
  final bool isLight;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color divider;

  const _TicketDetailsSheet({
    required this.ticketId,
    required this.isLight,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(28),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
          final ticket = SupportTicketModel.fromFirestore(snapshot.data!);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: secondaryTextColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ticket Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                  _StatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailItem('SUBJECT', ticket.title),
              const SizedBox(height: 20),
              _buildDetailItem('CATEGORY', ticket.category),
              const SizedBox(height: 20),
              _buildDetailItem('PRIORITY', ticket.priority.name.toUpperCase()),
              const SizedBox(height: 20),
              _buildDetailItem('CREATED ON', DateFormat('MMM dd, yyyy • hh:mm a').format(ticket.createdAt)),
              const SizedBox(height: 40),
              
              const Text('TIMELINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.info, letterSpacing: 2)),
              const SizedBox(height: 20),
              _buildTimeline(ticket.status, secondaryTextColor),
              
              const SizedBox(height: 40),
              if (ticket.status != TicketStatus.closed)
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).update({'status': 'closed'});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CLOSE TICKET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: secondaryTextColor.withOpacity(0.5), letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
      ],
    );
  }

  Widget _buildTimeline(TicketStatus status, Color secondary) {
    final steps = ['Created', 'Assigned', 'In Progress', 'Resolved'];
    int currentStep = 0;
    if (status == TicketStatus.assigned) currentStep = 1;
    if (status == TicketStatus.inProgress || status == TicketStatus.waitingForUser) currentStep = 2;
    if (status == TicketStatus.resolved || status == TicketStatus.closed) currentStep = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentStep;
        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppColors.success : secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: i < currentStep 
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Center(child: Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : secondary, fontSize: 10, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 8),
            Text(steps[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isActive ? AppColors.success : secondary.withOpacity(0.5))),
          ],
        );
      }),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}
