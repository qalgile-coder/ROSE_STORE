import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportChatStatus {
  open,
  waitingForCustomer,
  waitingForSupport,
  resolved,
  closed,
  reopened
}

class SupportChatModel {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final SupportChatStatus status;
  final String? agentId;
  final String? agentName;
  final bool isTypingCustomer;
  final bool isTypingAgent;
  final String? linkedOrderId;

  SupportChatModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.status = SupportChatStatus.open,
    this.agentId,
    this.agentName,
    this.isTypingCustomer = false,
    this.isTypingAgent = false,
    this.linkedOrderId,
  });

  factory SupportChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SupportChatModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      customerAvatar: data['customerAvatar'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      status: SupportChatStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SupportChatStatus.open,
      ),
      agentId: data['agentId'],
      agentName: data['agentName'],
      isTypingCustomer: data['isTypingCustomer'] ?? false,
      isTypingAgent: data['isTypingAgent'] ?? false,
      linkedOrderId: data['linkedOrderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatar': customerAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'status': status.name,
      'agentId': agentId,
      'agentName': agentName,
      'isTypingCustomer': isTypingCustomer,
      'isTypingAgent': isTypingAgent,
      'linkedOrderId': linkedOrderId,
    };
  }
}
