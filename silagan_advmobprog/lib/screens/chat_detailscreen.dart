import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final UserService _userService = UserService();

  late Future<String> _currentUserIdFuture;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    // 1. Ask Firebase directly (most reliable)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }

    // 2. Fallback to local storage
    final userData = await _userService.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI update: Clear input and scroll immediately
    _msgCtrl.clear();
    _msgFocus.requestFocus();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    try {
      await chatService.sendMessage(receiverId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = (widget.tappedUser['firstName'] ?? '').toString();
    const Color shopeeOrange = Color(0xFFEE4D2D);

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            centerTitle: true,
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            title: CustomText(
              text: tappedUserName,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          body: Column(
            children: [
              // Messages List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: CustomText(
                          text: 'Start a conversation!',
                          fontSize: 16.sp,
                          color: Colors.grey,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true, // Auto-scroll to bottom behavior
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 12.w,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final timestamp = data['timestamp'] as Timestamp?;

                        // Cloud Firestore automatically flags local un-synced data
                        final isPending = doc.metadata.hasPendingWrites;

                        // Enhancement: Slide and Fade Animation per message
                        return TweenAnimationBuilder(
                          key: ValueKey(doc.id),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: _buildMessageBubble(
                            msgText: msgText,
                            isMe: isMe,
                            isPending: isPending,
                            timestamp: timestamp,
                            shopeeOrange: shopeeOrange,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Composer
              _buildMessageComposer(currentUserId, tappedUserId, shopeeOrange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String msgText,
    required bool isMe,
    required bool isPending,
    required Timestamp? timestamp,
    required Color shopeeOrange,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isMe ? shopeeOrange : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            CustomText(
              text: msgText,
              fontSize: 15.sp,
              color: isMe ? Colors.white : Colors.black87,
              fontWeight: FontWeight.normal,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: _formatTime(timestamp),
                  fontSize: 10.sp,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    isPending
                        ? Icons.access_time_rounded
                        : Icons.done_all_rounded,
                    size: 14.sp,
                    color: isPending ? Colors.white70 : Colors.white,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(
    String currentUserId,
    String tappedUserId,
    Color themeColor,
  ) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                focusNode: _msgFocus,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(currentUserId, tappedUserId),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => _send(currentUserId, tappedUserId),
              child: CircleAvatar(
                radius: 22.r,
                backgroundColor: themeColor,
                child: Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
