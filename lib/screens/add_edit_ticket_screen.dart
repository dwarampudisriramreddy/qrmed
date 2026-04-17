import 'package:flutter/material.dart';
import 'package:supreme_institution/models/ticket.dart';

class AddEditTicketScreen extends StatefulWidget {
  final Ticket? ticket;

  const AddEditTicketScreen({super.key, this.ticket});

  @override
  _AddEditTicketScreenState createState() => _AddEditTicketScreenState();
}

class _AddEditTicketScreenState extends State<AddEditTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketStatus _selectedStatus = TicketStatus.open;

  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      _titleController.text = widget.ticket!.title ?? '';
      _descriptionController.text = widget.ticket!.description ?? '';
      _selectedStatus = widget.ticket!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTicket() {
    if (_formKey.currentState!.validate()) {
      final newTicket = Ticket(
        id: widget.ticket?.id ?? DateTime.now().toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        raisedBy: widget.ticket?.raisedBy ?? '', // This will be set in the calling screen
        raisedTo: widget.ticket?.raisedTo ?? '', // This will be set in the calling screen
        timestamp: widget.ticket?.timestamp ?? DateTime.now(),
      );
      Navigator.of(context).pop(newTicket);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket == null ? 'Add Ticket' : 'Edit Ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.ticket != null)
                DropdownButtonFormField<TicketStatus>(
                  isExpanded: true,
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  selectedItemBuilder: (BuildContext context) {
                    return TicketStatus.values.map((TicketStatus status) {
                      return Text(
                        status.toString().split('.').last,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                  items: TicketStatus.values.map((TicketStatus status) {
                    return DropdownMenuItem<TicketStatus>(
                      value: status,
                      child: Text(
                        status.toString().split('.').last,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                    });
                  },
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTicket,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.ticket == null ? 'Add Ticket' : 'Update Ticket',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
