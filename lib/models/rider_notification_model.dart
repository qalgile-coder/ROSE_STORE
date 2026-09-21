import 'package:cloud_firestore/cloud_firestore.dart';

enum RiderNotificationType {
  newRequest,
  deliveryCancelled,
  assignmentUpdated,
  paymentReceived,
  bonusEarned,
  systemAnnouncement,
  general
}

class RiderNotificationModel {
  final String id;
  final String title;
  final String message;
  final RiderNotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  RiderNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory RiderNotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RiderNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseType(data['type']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  static RiderNotificationType _parseType(String? type) {
    return RiderNotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => RiderNotificationType.general,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'data': data,
    };
  }
}
