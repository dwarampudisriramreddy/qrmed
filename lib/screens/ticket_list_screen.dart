import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/models/ticket_message.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/screens/ticket_chat_screen.dart';
import 'package:intl/intl.dart';

class TicketListScreen extends StatefulWidget {
  final String userId;
  final String userRole; // 'admin' or 'college'
  final String? collegeId;
  final String? collegeName;

  const TicketListScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.collegeId,
    this.collegeName,
  });

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
      if (widget.userRole == 'admin') {
        Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
      }
    });
  }

  Future<void> _openOrCreateChat(String? collegeId, String? collegeName) async {
    if (collegeId == null) return;

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    String ticketId;

    if (widget.userRole == 'admin') {
      // Admin: find ticket with this college
      final tickets = ticketProvider.getTicketsForAdmin();
      final existingTicket = tickets.firstWhere(
        (t) => t.collegeId == collegeId,
        orElse: () => Ticket(
          id: '',
          raisedBy: '',
          raisedTo: '',
          timestamp: DateTime.now(),
        ),
      );

      if (existingTicket.id.isEmpty) {
        // Create new ticket
        ticketId = await ticketProvider.getOrCreateTicket(
          collegeId: collegeId,
          collegeName: collegeName ?? 'College',
        );
      } else {
        ticketId = existingTicket.id;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketChatScreen(
              ticketId: ticketId,
              userId: widget.userId,
              userRole: widget.userRole,
              collegeId: collegeId,
              collegeName: collegeName,
              otherPartyName: collegeName,
            ),
          ),
        );
      }
    } else {
      // College: get or create ticket with admin
      ticketId = await ticketProvider.getOrCreateTicket(
        collegeId: widget.collegeId!,
        collegeName: widget.collegeName ?? 'College',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketChatScreen(
              ticketId: ticketId,
              userId: widget.userId,
              userRole: widget.userRole,
              collegeId: widget.collegeId,
              collegeName: widget.collegeName,
              otherPartyName: 'Admin',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    if (widget.userRole == 'admin') {
      // Admin view: Show list of colleges
      final collegeProvider = Provider.of<CollegeProvider>(context);
      final colleges = collegeProvider.colleges;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Tickets'),
          backgroundColor: const Color(0xFF075E54),
          foregroundColor: Colors.white,
        ),
        body: colleges.isEmpty
            ? const Center(child: Text('No colleges found'))
            : ListView.builder(
                itemCount: colleges.length,
                itemBuilder: (context, index) {
                  final college = colleges[index];
                  return _buildCollegeChatTile(college.id, college.name);
                },
              ),
      );
    } else {
      // College view: Show single chat with admin
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tickets'),
          backgroundColor: const Color(0xFF075E54),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () => _openOrCreateChat(
              widget.collegeId,
              widget.collegeName,
            ),
            icon: const Icon(Icons.chat),
            label: const Text('Chat with Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCollegeChatTile(String collegeId, String collegeName) {
    // Get ticket for this college
    final ticketProvider = Provider.of<TicketProvider>(context);
    final tickets = ticketProvider.getTicketsForAdmin();
    Ticket? ticket;
    try {
      ticket = tickets.firstWhere(
        (t) => t.collegeId == collegeId,
      );
    } catch (e) {
      ticket = null;
    }

    return StreamBuilder<List<TicketMessage>>(
      stream: ticket != null 
          ? ticketProvider.getMessagesStream(ticket.id)
          : Stream.value(<TicketMessage>[]),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        final lastMessage = messages.isNotEmpty ? messages.last : null;
        final unreadCount = messages
                .where((msg) => msg.senderId != widget.userId && !msg.isRead)
                .length;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF075E54),
            child: Text(
              collegeName.isNotEmpty ? collegeName[0].toUpperCase() : 'C',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            collegeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            lastMessage?.message ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessage != null)
                Text(
                  _formatTime(lastMessage.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () => _openOrCreateChat(collegeId, collegeName),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}

