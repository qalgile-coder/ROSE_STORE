import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  vendorRegistration,
  riderRegistration,
  newOrder,
  withdrawalRequest,
  systemAlert,
  supportTicket,
  general
}

class ActivityModel {
  final String id;
  final String title;
  final String subtitle;
  final ActivityType type;
  final DateTime timestamp;
  final Color color;
  final IconData icon;

  ActivityModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    required this.color,
    required this.icon,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final type = _parseType(data['type']);
    return ActivityModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      type: type,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      color: Color(data['color'] ?? 0xFF6366F1),
      icon: _getIconForType(type),
    );
  }

  static IconData _getIconForType(ActivityType type) {
    switch (type) {
      case ActivityType.vendorRegistration: return Icons.storefront_rounded;
      case ActivityType.riderRegistration: return Icons.directions_bike_rounded;
      case ActivityType.newOrder: return Icons.receipt_long_rounded;
      case ActivityType.withdrawalRequest: return Icons.payments_rounded;
      case ActivityType.systemAlert: return Icons.warning_amber_rounded;
      case ActivityType.supportTicket: return Icons.support_agent_rounded;
      case ActivityType.general: return Icons.notifications_rounded;
    }
  }

  static ActivityType _parseType(String? type) {
    return ActivityType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ActivityType.general,
    );
  }
}
