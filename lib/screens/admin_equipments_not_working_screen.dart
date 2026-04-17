import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/widgets/management_list_widget.dart';
import 'package:supreme_institution/widgets/modern_details_dialog.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';

class AdminEquipmentsNotWorkingScreen extends StatefulWidget {
  const AdminEquipmentsNotWorkingScreen({super.key});

  @override
  State<AdminEquipmentsNotWorkingScreen> createState() => _AdminEquipmentsNotWorkingScreenState();
}

class _AdminEquipmentsNotWorkingScreenState extends State<AdminEquipmentsNotWorkingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch latest equipment data when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments();
    });
  }

  void _showEquipmentDetails(Equipment equipment, BuildContext context) {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    String collegeName = equipment.collegeId;
    try {
      final college = collegeProvider.colleges.firstWhere(
        (c) => c.id == equipment.collegeId,
      );
      collegeName = college.name;
    } catch (e) {
      // If college not found, use collegeId as fallback
    }

    showDialog(
      context: context,
      builder: (ctx) => ModernDetailsDialog(
        title: 'Equipment Details',
        details: [
          DetailRow(label: 'ID', value: equipment.id),
          DetailRow(label: 'Name', value: equipment.name),
          DetailRow(label: 'College', value: collegeName),
          DetailRow(label: 'Type', value: equipment.type),
          DetailRow(label: 'Group', value: equipment.group),
          DetailRow(label: 'Mode', value: equipment.mode),
          DetailRow(label: 'Manufacturer', value: equipment.manufacturer),
          DetailRow(label: 'Serial Number', value: equipment.serialNo),
          DetailRow(label: 'Department', value: equipment.department),
          DetailRow(label: 'Status', value: equipment.status),
          DetailRow(label: 'Service Status', value: equipment.service),
          DetailRow(
            label: 'Warranty Upto',
            value: equipment.warrantyUpto != null
                ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!)
                : '-',
          ),
          DetailRow(
            label: 'Purchased Cost',
            value: '₹${equipment.purchasedCost.toString()}',
          ),
          DetailRow(
            label: 'Installation Date',
            value: DateFormat('yyyy-MM-dd').format(equipment.installationDate),
          ),
          DetailRow(
            label: 'Employee Assigned',
            value: equipment.assignedEmployeeId ?? '-',
          ),
        ],
        qrCodeWidget: QrImageView(
          data: equipment.id,
          version: QrVersions.auto,
          size: 150,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final notWorkingEquipments = equipmentProvider.equipments
        .where((e) => e.isNotWorking)
        .toList();

    if (notWorkingEquipments.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No non-working equipments to export.')),
        );
      }
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Equipments Not Working'];

      // Add headers
      List<String> headers = [
        'ID', 'Name', 'College', 'Type', 'Group', 'Mode', 'Manufacturer',
        'Serial Number', 'Department', 'Status', 'Service Status',
        'Warranty Upto', 'Purchased Cost', 'Installation Date',
        'Employee Assigned', 'Remarks', 'Need of Spares',
      ];
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Set column widths for Remarks and Need of Spares
      sheetObject.setColumnWidth(15, 40);
      sheetObject.setColumnWidth(16, 40);

      // Add data rows
      for (var equipment in notWorkingEquipments) {
        String collegeName = equipment.collegeId;
        try {
          final college = collegeProvider.colleges.firstWhere(
            (c) => c.id == equipment.collegeId,
          );
          collegeName = college.name;
        } catch (e) {
          // Fallback if college not found
        }

        sheetObject.appendRow([
          TextCellValue(equipment.id),
          TextCellValue(equipment.name),
          TextCellValue(collegeName),
          TextCellValue(equipment.type),
          TextCellValue(equipment.group),
          TextCellValue(equipment.mode),
          TextCellValue(equipment.manufacturer),
          TextCellValue(equipment.serialNo),
          TextCellValue(equipment.department),
          TextCellValue(equipment.status),
          TextCellValue(equipment.service),
          TextCellValue(equipment.warrantyUpto != null
              ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!)
              : '-'),
          DoubleCellValue(equipment.purchasedCost),
          TextCellValue(DateFormat('yyyy-MM-dd').format(equipment.installationDate)),
          TextCellValue(equipment.assignedEmployeeId ?? '-'),
          TextCellValue(''), // Remarks column
          TextCellValue(''), // Need of Spares column
        ]);
      }

      // Save the file
      List<int>? fileBytes = excel.save(fileName: 'equipments_not_working.xlsx');
      if (fileBytes != null) {
        final String fileName = 'equipments_not_working_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        
        // Use FileSaver for cross-platform saving
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported $fileName successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate Excel file.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting to Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    
    // Use the helper method for consistent filtering
    final notWorkingEquipments = equipmentProvider.equipments
        .where((e) {
          final isNotWorking = e.isNotWorking;
          
          // Debug logging to help diagnose issues
          if (isNotWorking) {
            debugPrint('🔍 [AdminEquipmentsNotWorking] Found non-working: ${e.name} (ID: ${e.id}) - Status: "${e.status.trim()}"');
          }
          
          return isNotWorking;
        })
        .toList();
    
    debugPrint('📊 [AdminEquipmentsNotWorking] Total equipments: ${equipmentProvider.equipments.length}');
    debugPrint('📊 [AdminEquipmentsNotWorking] Not working count: ${notWorkingEquipments.length}');
    
    // Log all status values for debugging
    final allStatuses = equipmentProvider.equipments.map((e) => e.status.trim()).toSet();
    debugPrint('📊 [AdminEquipmentsNotWorking] All unique statuses: $allStatuses');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipments Not Working'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments();
        },
        child: ManagementListWidget(
          items: notWorkingEquipments.map((equipment) {
          return ManagementListItem(
            id: equipment.id,
            title: equipment.name,
            subtitle: equipment.department,
            icon: Icons.devices_other,
            iconColor: const Color(0xFFDC2626),
            badge: equipment.status,
            badgeColor: equipment.status == 'Under Maintenance'
                ? Colors.orange
                : Colors.red,
            actions: [
              ManagementAction(
                label: 'View',
                icon: Icons.remove_red_eye,
                color: const Color(0xFF2563EB),
                onPressed: () => _showEquipmentDetails(equipment, context),
              ),
              ManagementAction(
                label: 'Mark Working',
                icon: Icons.check_circle,
                color: Colors.green,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Restore'),
                      content: Text('Mark ${equipment.name} as Working?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
                    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                    
                    final updatedEquipment = equipment.copyWith(status: 'Working');
                    await equipmentProvider.updateEquipment(
                      equipment.id, 
                      updatedEquipment,
                      notificationProvider: notificationProvider,
                      updatedByRole: 'admin',
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Equipment marked as working and college notified.')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        }).toList(),
          emptyMessage: 'No non-working equipments found.',
        ),
      ),
    );
  }
}

