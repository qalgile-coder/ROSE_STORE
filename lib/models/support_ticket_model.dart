import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum TicketStatus {
  open,
  assigned,
  inProgress,
  waitingForUser,
  resolved,
  closed
}

enum TicketPriority {
  low,
  medium,
  high
}

class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final UserRole userRole;
  final String category;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      userRole: _parseRole(data['userRole']),
      category: data['category'] ?? 'General',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: _parseStatus(data['status']),
      priority: _parsePriority(data['priority']),
      attachmentUrls: data['attachmentUrls'] != null ? List<String>.from(data['attachmentUrls']) : [],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'vendor':
        return UserRole.vendor;
      case 'customer':
        return UserRole.customer;
      case 'rider':
        return UserRole.rider;
      default:
        return UserRole.customer;
    }
  }

  static TicketStatus _parseStatus(String? status) {
    return TicketStatus.values.firstWhere((e) => e.name == status, orElse: () => TicketStatus.open);
  }

  static TicketPriority _parsePriority(String? priority) {
    return TicketPriority.values.firstWhere((e) => e.name == priority, orElse: () => TicketPriority.medium);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole.name,
      'category': category,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
    };
  }
}

class SupportMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String type; // text, image, voice, pdf, order
  final String? attachmentUrl;
  final String? linkedId; // e.g. Order ID
  final DateTime timestamp;

  SupportMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.type = 'text',
    this.attachmentUrl,
    this.linkedId,
    required this.timestamp,
  });

  factory SupportMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SupportMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'customer',
      message: data['message'] ?? data['text'] ?? '',
      type: data['type'] ?? 'text',
      attachmentUrl: data['attachmentUrl'] ?? data['imageUrl'],
      linkedId: data['linkedId'],
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'type': type,
      'attachmentUrl': attachmentUrl,
      'linkedId': linkedId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
