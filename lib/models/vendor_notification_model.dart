import 'package:cloud_firestore/cloud_firestore.dart';

enum VendorNotificationType {
  newOrder,
  orderCancelled,
  newReview,
  lowStock,
  shopApproved,
  bannerUpdated,
  couponExpired,
  systemAnnouncement,
  general
}

class VendorNotificationModel {
  final String id;
  final String title;
  final String message;
  final VendorNotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Stores IDs like orderId, productId, etc.

  VendorNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory VendorNotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VendorNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseType(data['type']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  static VendorNotificationType _parseType(String? type) {
    return VendorNotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => VendorNotificationType.general,
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
