import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supreme_institution/screens/qr_scanner_screen.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/employee_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/widgets/modern_details_dialog.dart';

class FindEquipmentWidget extends StatefulWidget {
  final String currentEmployeeId;
  const FindEquipmentWidget({super.key, required this.currentEmployeeId});

  @override
  State<FindEquipmentWidget> createState() => _FindEquipmentWidgetState();
}

class _FindEquipmentWidgetState extends State<FindEquipmentWidget> {

  String _extractId(String code) {
    if (code.startsWith('http')) {
      try {
        final uri = Uri.parse(code);
        return uri.queryParameters['id'] ?? code;
      } catch (e) {
        // Fallback for malformed URLs that might still contain id=
        if (code.contains('id=')) {
          final parts = code.split('id=');
          if (parts.length > 1) {
            return parts[1].split('&')[0];
          }
        }
        return code;
      }
    }
    return code;
  }

  Future<void> _scanQrCode() async {
    final scannedCode = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
    if (scannedCode != null && scannedCode is String) {
      final equipmentId = _extractId(scannedCode);
      _viewEquipmentDetails(equipmentId);
    }
  }

  Future<void> _manualIdEntry() async {
    String? enteredId = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        TextEditingController idController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Equipment ID'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(hintText: 'Equipment ID'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Find'),
              onPressed: () {
                Navigator.of(dialogContext).pop(idController.text);
              },
            ),
          ],
        );
      },
    );

    if (enteredId != null && enteredId.isNotEmpty) {
      final equipmentId = _extractId(enteredId);
      _viewEquipmentDetails(equipmentId);
    }
  }

  void _viewEquipmentDetails(String equipmentId) async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    
    final equipment = await equipmentProvider.getEquipmentById(equipmentId);
    
    if (!mounted) return;

    if (equipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment not found.')),
      );
      return;
    }

    // Fetch the current employee to check department for HOD logic
    final currentEmployee = await employeeProvider.getEmployeeById(widget.currentEmployeeId);

    if (!mounted) return;

    // Check if employee has permission to change status
    final isAssigned = equipment.assignedEmployeeId == widget.currentEmployeeId;
    final isHodOfDept = currentEmployee?.role == 'HOD' && currentEmployee?.department == equipment.department;
    final canChangeStatus = isAssigned || isHodOfDept;

    showDialog(
      context: context,
      builder: (ctx) => ModernDetailsDialog(
        title: equipment.name,
        details: [
          DetailRow(label: 'ID', value: equipment.id),
          DetailRow(label: 'Status', value: equipment.status),
          DetailRow(label: 'Department', value: equipment.department),
          DetailRow(label: 'Group', value: equipment.group),
          DetailRow(label: 'Manufacturer', value: equipment.manufacturer),
          DetailRow(label: 'Type', value: equipment.type),
          DetailRow(label: 'Mode', value: equipment.mode),
          DetailRow(label: 'Serial Number', value: equipment.serialNo),
          DetailRow(label: 'Service', value: equipment.service),
          DetailRow(label: 'Purchased Cost', value: '₹${equipment.purchasedCost}'),
          DetailRow(
            label: 'Installation Date',
            value: DateFormat.yMd().format(equipment.installationDate),
          ),
          if (equipment.hasWarranty && equipment.warrantyUpto != null)
            DetailRow(
              label: 'Warranty Upto',
              value: DateFormat.yMd().format(equipment.warrantyUpto!),
            ),
          if (equipment.assignedEmployeeId != null && equipment.assignedEmployeeId!.isNotEmpty)
            DetailRow(label: 'Assigned To', value: equipment.assignedEmployeeId!),
          DetailRow(label: 'College ID', value: equipment.collegeId),
        ],
        qrCodeWidget: QrImageView(
          data: equipment.id,
          version: QrVersions.auto,
          size: 150,
          backgroundColor: Colors.white,
        ),
        actionButtons: canChangeStatus ? [
          ActionButton(
            label: equipment.status == 'Working' ? 'Mark Not Working' : 'Mark Working',
            icon: equipment.status == 'Working' ? Icons.error_outline : Icons.check_circle_outline,
            color: equipment.status == 'Working' ? Colors.red : Colors.green,
            onPressed: () async {
              final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
              final newStatus = equipment.status == 'Working' ? 'Not Working' : 'Working';
              final updatedEquipment = equipment.copyWith(status: newStatus);
              
              await equipmentProvider.updateEquipment(
                equipment.id, 
                updatedEquipment,
                notificationProvider: notificationProvider,
                updatedByRole: 'employee',
              );
              
              if (mounted) {
                Navigator.of(ctx).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Equipment status updated to $newStatus')),
                );
              }
            },
          )
        ] : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            onPressed: _scanQrCode,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.input),
            label: const Text('Enter ID Manually'),
            onPressed: _manualIdEntry,
          ),
        ],
      ),
    );
  }
}