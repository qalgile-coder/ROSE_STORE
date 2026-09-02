import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../core/providers.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _messageController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = ref.read(userModelProvider).asData?.value;
    if (user == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    final chatId = 'support_${user.uid}';

    await _db.collection('support_chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'userName': user.name,
      'userRole': user.role.name,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await _db.collection('support_chats').doc(chatId).collection('messages').add({
      'text': text,
      'senderId': user.uid,
      'senderName': user.name,
      'timestamp': FieldValue.serverTimestamp(),
      'isFromAdmin': false,
    });

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

    final chatId = 'support_${user.uid}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zen Mart Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Admin Online', style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.05),
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('support_chats').doc(chatId).collection('messages')
                  .orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.rider));
                }
                
                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = !data['isFromAdmin'];
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null ? DateFormat('hh:mm a').format(timestamp.toDate()) : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white10,
                                  child: Icon(Icons.support_agent_rounded, size: 16, color: Colors.white70),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.rider : Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isMe ? 20 : 0),
                                      bottomRight: Radius.circular(isMe ? 0 : 20),
                                    ),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Text(
                                    data['text'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.rider.withOpacity(0.2),
                                  backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                                  child: user.profilePicture == null 
                                      ? Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10))
                                      : null,
                                ),
                              ],
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 40, right: 40),
                            child: Text(
                              timeStr,
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Area
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Describe your issue...',
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: AppColors.rider,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.rider, blurRadius: 10, spreadRadius: -5),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
