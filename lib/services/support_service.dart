import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket_model.dart';
import '../models/support_chat_model.dart';
import '../models/notification_model.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';

class SupportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications;

  SupportService(this._notifications);

  // --- LIVE CHAT SUPPORT ---

  /// Get or create a support chat for a customer
  Future<String> getOrCreateChat(String customerId, String customerName, String? avatar) async {
    final chatQuery = await _db
        .collection('support_chats')
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    }

    // Create new chat
    final docRef = await _db.collection('support_chats').add({
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatar': avatar,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'status': SupportChatStatus.open.name,
      'agentId': null,
      'agentName': null,
      'isTypingCustomer': false,
      'isTypingAgent': false,
      'linkedOrderId': null,
    });

    // Send AI Welcome Message
    await sendSupportMessage(docRef.id, SupportMessageModel(
      id: '',
      senderId: 'system',
      senderName: 'Zen MArt AI',
      senderRole: 'system',
      message: 'Hello 👋\n\nWelcome to Zen MArt Support.\n\nPlease describe your issue.\n\nIf your issue relates to an order, please attach the order.\n\nOur support team will reply shortly.',
      timestamp: DateTime.now(),
    ));

    // Notify Super Admin
    await _db.collection('admin_notifications').add({
      'title': 'New Live Chat',
      'message': '$customerName started a support conversation.',
      'type': 'support_chat',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'data': {'chatId': docRef.id},
    });

    return docRef.id;
  }

  /// Get stream of messages for a chat
  Stream<List<SupportMessageModel>> getSupportMessages(String chatId) {
    return _db
        .collection('support_messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('Fetched ${snapshot.docs.length} messages for chat $chatId');
          return snapshot.docs
            .map((doc) => SupportMessageModel.fromFirestore(doc))
            .toList();
        });
  }

  /// Send message in support chat
  Future<void> sendSupportMessage(String chatId, SupportMessageModel message) async {
    await _db.collection('support_messages').add({
      ...message.toMap(),
      'chatId': chatId,
    });

    // Update chat metadata
    await _db.collection('support_chats').doc(chatId).update({
      'lastMessage': message.message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(message.senderRole == 'customer' ? 0 : 0), // Logic depends on who reads it
      'status': message.senderRole == 'customer' ? SupportChatStatus.waitingForSupport.name : SupportChatStatus.waitingForCustomer.name,
    });
    
    // If it's a customer message, increment unread for admin
    if (message.senderRole == 'customer') {
       await _db.collection('support_chats').doc(chatId).update({
         'unreadCount': FieldValue.increment(1),
       });
       
       // Notify Admin
       _notifications.notifyRole(
         role: UserRole.superAdmin, 
         title: 'New message from ${message.senderName}', 
         body: message.message.length > 50 ? '${message.message.substring(0, 47)}...' : message.message,
       );
    } else if (message.senderRole != 'system') {
       // If it's an admin message, notify the customer
       final chatDoc = await _db.collection('support_chats').doc(chatId).get();
       final customerId = chatDoc.data()?['customerId'];
       if (customerId != null) {
         _notifications.notifyUser(
           userId: customerId, 
           title: 'Support Team Replied', 
           body: message.message.length > 50 ? '${message.message.substring(0, 47)}...' : message.message,
         );
       }
    }
  }

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    await _db.collection('support_chats').doc(chatId).update({
      'unreadCount': 0,
    });
  }

  /// Update typing indicator
  Future<void> setTypingStatus(String chatId, bool isCustomer, bool isTyping) async {
    await _db.collection('support_chats').doc(chatId).update({
      isCustomer ? 'isTypingCustomer' : 'isTypingAgent': isTyping,
    });
  }

  /// Link order to chat
  Future<void> linkOrderToChat(String chatId, String orderId) async {
    await _db.collection('support_chats').doc(chatId).update({
      'linkedOrderId': orderId,
    });
    
    // Also send an automated message about the linked order
    await sendSupportMessage(chatId, SupportMessageModel(
      id: '',
      senderId: 'system',
      senderName: 'System',
      senderRole: 'system',
      message: '📌 Order #$orderId has been linked to this conversation.',
      timestamp: DateTime.now(),
    ));
  }

  /// Get chat data stream
  Stream<SupportChatModel?> getChatStream(String chatId) {
    return _db.collection('support_chats').doc(chatId).snapshots().map((doc) {
      if (doc.exists) return SupportChatModel.fromFirestore(doc);
      return null;
    });
  }

  /// Check if any admin is online
  Stream<bool> isAdminOnline() {
    return _db
        .collection('users')
        .where('role', whereIn: ['admin', 'super_admin'])
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// End a support chat (Resolve it)
  Future<void> endChat(String chatId) async {
    await _db.collection('support_chats').doc(chatId).update({
      'status': SupportChatStatus.resolved.name,
      'lastMessage': '🏁 Conversation ended by support.',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    // Also send an automated message
    await sendSupportMessage(chatId, SupportMessageModel(
      id: '',
      senderId: 'system',
      senderName: 'System',
      senderRole: 'system',
      message: '🏁 This conversation has been marked as resolved.',
      timestamp: DateTime.now(),
    ));
  }

  // --- EXISTING TICKET STUFF (Kept for compatibility) ---

  Future<String> createTicket(SupportTicketModel ticket) async {
    final docRef = await _db.collection('support_tickets').add(ticket.toMap());
    await _db.collection('admin_notifications').add({
      'title': 'New Support Ticket',
      'message': '${ticket.userName} created a new ticket: ${ticket.title}',
      'type': 'support_ticket',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'data': {'ticketId': docRef.id, 'userId': ticket.userId},
    });
    return docRef.id;
  }

  Stream<List<SupportTicketModel>> getUserTickets(String userId) {
    return _db
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs.map((doc) => SupportTicketModel.fromFirestore(doc)).toList();
          tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return tickets;
        });
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == TicketStatus.resolved) {
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      final professionalMessage = '''Hello,

We're happy to let you know that your support ticket has been marked as Resolved.

We believe your issue has been addressed. If everything is working as expected, no further action is required.

If you're still experiencing the issue or have additional questions, you can reopen this ticket or create a new support request within the next 7 days.

Thank you for contacting our support team. We appreciate your patience and are always here to help.

Status: Resolved
Resolved On: $now
Ticket ID: #${ticketId.substring(0, 8).toUpperCase()}''';

      await sendMessage(ticketId, SupportMessageModel(
        id: '',
        senderId: 'system',
        senderName: 'Zen Mart Support',
        senderRole: 'system',
        message: professionalMessage,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> sendMessage(String ticketId, SupportMessageModel message) async {
    await _db.collection('support_tickets').doc(ticketId).collection('messages').add(message.toMap());
    await _db.collection('support_tickets').doc(ticketId).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  Stream<List<SupportTicketModel>> getAllTickets() {
    return _db
        .collection('support_tickets')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<SupportMessageModel>> getTicketMessages(String ticketId) {
    return _db
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SupportMessageModel.fromFirestore(doc)).toList());
  }
}
