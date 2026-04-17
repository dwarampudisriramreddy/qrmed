import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/models/ticket_message.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:intl/intl.dart';

class TicketChatScreen extends StatefulWidget {
  final String ticketId;
  final String userId;
  final String userRole; // 'admin' or 'college'
  final String? collegeId;
  final String? collegeName;
  final String? otherPartyName; // Name of the other party (college or admin)

  const TicketChatScreen({
    super.key,
    required this.ticketId,
    required this.userId,
    required this.userRole,
    this.collegeId,
    this.collegeName,
    this.otherPartyName,
  });

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<TicketMessage>> _messagesStream;
  bool _isMarkingAsRead = false;

  @override
  void initState() {
    super.initState();
    
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    _messagesStream = ticketProvider.getMessagesStream(widget.ticketId);

    // Initial mark as read
    _markMessagesAsRead();

    // Listen to the stream to mark new incoming messages as read
    _messagesStream.listen((messages) {
      if (mounted) {
        final hasUnread = messages.any((msg) => msg.senderId != widget.userId && !msg.isRead);
        if (hasUnread) {
          _markMessagesAsRead();
        }
      }
    });
  }

  void _markMessagesAsRead() async {
    if (_isMarkingAsRead) return;
    
    _isMarkingAsRead = true;
    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      await ticketProvider.markAllMessagesAsRead(widget.ticketId, widget.userId);
    } catch (e) {
      debugPrint('Error marking messages as read in TicketChatScreen: $e');
    } finally {
      if (mounted) {
        _isMarkingAsRead = false;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    ticketProvider.sendMessage(
      ticketId: widget.ticketId,
      senderId: widget.userId,
      senderName: widget.userRole == 'admin' 
          ? 'Admin' 
          : (widget.collegeName ?? 'College'),
      message: message,
    );

    _messageController.clear();
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherPartyName ?? 
              (widget.userRole == 'admin' ? 'Admin' : widget.collegeName ?? 'College'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.userRole == 'admin' 
                  ? (widget.collegeName ?? 'College')
                  : 'Admin',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54), // WhatsApp green
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<List<TicketMessage>>(
                stream: ticketProvider.getMessagesStream(widget.ticketId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.userId;
                      
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            // Message input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF075E54),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage message, bool isMe) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isToday = message.timestamp.day == DateTime.now().day &&
        message.timestamp.month == DateTime.now().month &&
        message.timestamp.year == DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.senderName.isNotEmpty 
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFFDCF8C6) // WhatsApp sent message color
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(isMe ? 8 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF075E54),
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeFormat.format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead 
                              ? const Color(0xFF075E54)
                              : Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

