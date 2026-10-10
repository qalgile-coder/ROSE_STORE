import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../models/emergency_report_model.dart';
import '../../../models/support_ticket_model.dart';

class EmergencyDetailsScreen extends ConsumerWidget {
  final String reportId;
  const EmergencyDetailsScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(emergencyReportStreamProvider(reportId));
    final timelineAsync = ref.watch(emergencyTimelineProvider(reportId));
    final messagesAsync = ref.watch(emergencyMessagesProvider(reportId));
    
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? AppColors.lightBackground : AppColors.supportDarkBackground;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.supportDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.supportDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.supportDarkTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Investigation Status', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) return const Center(child: Text('Report not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(report, cardColor, textColor),
                const SizedBox(height: 32),
                _buildSectionTitle('CASE TIMELINE', textColor),
                const SizedBox(height: 16),
                _buildTimeline(timelineAsync, isLight, secondaryTextColor, textColor),
                const SizedBox(height: 32),
                _buildSectionTitle('CASE DETAILS', textColor),
                const SizedBox(height: 16),
                _buildDetailsCard(report, cardColor, textColor, secondaryTextColor),
                const SizedBox(height: 32),
                _buildSectionTitle('MESSAGES FROM INVESTIGATOR', textColor),
                const SizedBox(height: 16),
                _buildMessagesList(messagesAsync, cardColor, textColor, secondaryTextColor, isLight),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatusHeader(EmergencyReportModel report, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Row(
        children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.redAccent, child: Icon(Icons.security_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Status: ${report.status.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) => Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color.withOpacity(0.5), letterSpacing: 1.5));

  Widget _buildTimeline(AsyncValue<List<EmergencyTimelineEvent>> timelineAsync, bool isLight, Color secondary, Color textColor) {
    return timelineAsync.when(
      data: (events) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                  if (index != events.length - 1) Container(width: 2, height: 40, color: Colors.redAccent.withOpacity(0.2)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    Text(event.description, style: TextStyle(fontSize: 12, color: secondary, height: 1.4)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, hh:mm a').format(event.timestamp), style: TextStyle(fontSize: 10, color: secondary.withOpacity(0.5))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDetailsCard(EmergencyReportModel report, Color cardColor, Color textColor, Color secondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Report ID', '#${report.id.substring(0, 8).toUpperCase()}', textColor, secondary),
          _buildDetailRow('Description', report.description, textColor, secondary),
          if (report.orderId != null) _buildDetailRow('Related Order', '#${report.orderId!.substring(0, 8).toUpperCase()}', textColor, secondary),
          _buildDetailRow('Priority', report.priority, Colors.red, secondary),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valColor, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondary.withOpacity(0.5))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AsyncValue<List<SupportMessageModel>> messagesAsync, Color cardColor, Color textColor, Color secondary, bool isLight) {
    return messagesAsync.when(
      data: (messages) => messages.isEmpty 
          ? Center(child: Text('No messages yet.', style: TextStyle(color: secondary.withOpacity(0.5))))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderRole == 'customer';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.info : (isLight ? Colors.grey[100] : Colors.white.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg.message, style: TextStyle(color: isMe ? Colors.white : textColor, fontSize: 13)),
                  ),
                );
              },
            ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
