import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/providers/ticket_provider.dart';
import 'package:supreme_institution/screens/ticket_list_screen.dart';

enum TicketView {
  raisedByMe,
  assignedToMe,
}

class ManageTicketsScreen extends StatefulWidget {
  final String userId;
  final String userRole; // 'admin', 'college', 'employee'
  final String collegeId;
  final String? collegeName;

  const ManageTicketsScreen({
    super.key,
    required this.userId,
    required this.userRole,
    required this.collegeId,
    this.collegeName,
  });

  @override
  _ManageTicketsScreenState createState() => _ManageTicketsScreenState();
}

class _ManageTicketsScreenState extends State<ManageTicketsScreen> {
  @override
  Widget build(BuildContext context) {
    // Use the new chat-based ticket screen
    return TicketListScreen(
      userId: widget.userId,
      userRole: widget.userRole,
      collegeId: widget.collegeId,
      collegeName: widget.collegeName,
    );
  }
}
