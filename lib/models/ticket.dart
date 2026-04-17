enum TicketStatus {
  open,
  inProgress,
  closed,
}

class Ticket {
  final String id;
  final String? title;
  final String? description;
  final TicketStatus status;
  final String raisedBy; // Can be employeeId or collegeId
  final String raisedTo; // Can be collegeId or 'admin'
  final DateTime timestamp;
  final String? collegeId; // For college tickets
  final String? collegeName; // For display

  Ticket({
    required this.id,
    this.title,
    this.description,
    this.status = TicketStatus.open,
    required this.raisedBy,
    required this.raisedTo,
    required this.timestamp,
    this.collegeId,
    this.collegeName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'raisedBy': raisedBy,
      'raisedTo': raisedTo,
      'timestamp': timestamp.toIso8601String(),
      'collegeId': collegeId,
      'collegeName': collegeName,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: TicketStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TicketStatus.open,
      ),
      raisedBy: json['raisedBy'] as String,
      raisedTo: json['raisedTo'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => toJson();
  factory Ticket.fromMap(Map<String, dynamic> map) => Ticket.fromJson(map);
}
