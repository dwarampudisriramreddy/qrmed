import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supreme_institution/models/ticket.dart';
import 'package:supreme_institution/models/ticket_message.dart';
import 'package:uuid/uuid.dart';

class TicketProvider with ChangeNotifier {
  final CollectionReference _ticketCollection =
      FirebaseFirestore.instance.collection('tickets');
  final CollectionReference _messageCollection =
      FirebaseFirestore.instance.collection('ticket_messages');

  List<Ticket> _tickets = [];
  List<Ticket> get tickets => _tickets;

  Future<void> fetchTickets() async {
    try {
      final snapshot = await _ticketCollection.get();
      _tickets = snapshot.docs
          .map((doc) => Ticket.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    }
  }

  List<Ticket> getTicketsForUser(String userId) {
    return _tickets.where((ticket) => ticket.raisedBy == userId).toList();
  }

  List<Ticket> getTicketsForCollege(String collegeId) {
    return _tickets
        .where((ticket) =>
            ticket.raisedBy == collegeId || ticket.raisedTo == collegeId)
        .toList();
  }

  List<Ticket> getTicketsForAdmin() {
    return _tickets.where((ticket) => ticket.raisedTo == 'admin').toList();
  }

  // Get or create a ticket between college and admin
  Future<String> getOrCreateTicket({
    required String collegeId,
    required String collegeName,
  }) async {
    try {
      // Check if ticket already exists
      final existingTickets = await _ticketCollection
          .where('raisedBy', isEqualTo: collegeId)
          .where('raisedTo', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (existingTickets.docs.isNotEmpty) {
        return existingTickets.docs.first.id;
      }

      // Create new ticket
      final ticketId = const Uuid().v4();
      final ticket = Ticket(
        id: ticketId,
        raisedBy: collegeId,
        raisedTo: 'admin',
        timestamp: DateTime.now(),
        collegeId: collegeId,
        collegeName: collegeName,
      );

      await _ticketCollection.doc(ticketId).set(ticket.toJson());
      await fetchTickets();
      return ticketId;
    } catch (e) {
      debugPrint('Error getting/creating ticket: $e');
      rethrow;
    }
  }

  Future<void> addTicket(Ticket ticket) async {
    try {
      await _ticketCollection.doc(ticket.id).set(ticket.toJson());
      await fetchTickets();
    } catch (e) {
      debugPrint('Error adding ticket: $e');
      rethrow;
    }
  }

  Future<void> updateTicket(String id, Ticket newTicket) async {
    try {
      await _ticketCollection.doc(id).update(newTicket.toJson());
      await fetchTickets();
    } catch (e) {
      debugPrint('Error updating ticket: $e');
      rethrow;
    }
  }

  Future<void> deleteTicket(String id) async {
    try {
      // Delete all messages for this ticket
      final messagesSnapshot = await _messageCollection
          .where('ticketId', isEqualTo: id)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete ticket
      await _ticketCollection.doc(id).delete();
      await fetchTickets();
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
      rethrow;
    }
  }

  // Message operations
  Stream<List<TicketMessage>> getMessagesStream(String ticketId) {
    // Simplified stream without orderBy to avoid index requirements
    return _messageCollection
        .where('ticketId', isEqualTo: ticketId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) {
                try {
                  return TicketMessage.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  });
                } catch (e) {
                  debugPrint('Error parsing message: $e');
                  return null;
                }
              })
              .where((msg) => msg != null)
              .cast<TicketMessage>()
              .toList();
          
          // Sort manually in memory
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final ticketMessage = TicketMessage(
        id: messageId,
        ticketId: ticketId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
      );

      await _messageCollection.doc(messageId).set(ticketMessage.toJson());
      
      // Update ticket timestamp
      await _ticketCollection.doc(ticketId).update({
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageCollection.doc(messageId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Future<void> markAllMessagesAsRead(String ticketId, String userId) async {
    try {
      // Simplified query to avoid index requirements for isNotEqualTo
      final messagesSnapshot = await _messageCollection
          .where('ticketId', isEqualTo: ticketId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Only mark as read if the current user is NOT the sender
        if (data['senderId'] != userId) {
          batch.update(doc.reference, {'isRead': true});
          count++;
        }
      }
      
      if (count > 0) {
        await batch.commit();
        debugPrint('Marked $count messages as read for ticket $ticketId');
      }
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }
}
