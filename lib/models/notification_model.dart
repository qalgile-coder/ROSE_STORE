import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  vendorRegistration,
  newOrder,
  complaint,
  riderRequest,
  paymentAlert,
  lowStock,
  maintenance,
  securityAlert,
  supportTicket,
  orderStatus,
  offer,
  general
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // For storing related IDs (orderId, vendorId, etc.)

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseType(data['type']),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  static NotificationType _parseType(String? type) {
    if (type == 'order_status') return NotificationType.orderStatus;
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.general,
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
