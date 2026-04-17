import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supreme_institution/models/equipment.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import 'package:supreme_institution/providers/notification_provider.dart';
import 'package:supreme_institution/utils/web_download_stub.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

class MyEquipmentsScreen extends StatefulWidget {
  final String employeeId;
  final String collegeName;
  final String? employeeRole;
  final String? employeeDepartment;

  const MyEquipmentsScreen({
    super.key,
    required this.employeeId,
    required this.collegeName,
    this.employeeRole,
    this.employeeDepartment,
  });

  @override
  State<MyEquipmentsScreen> createState() => _MyEquipmentsScreenState();
}

class _MyEquipmentsScreenState extends State<MyEquipmentsScreen> {
  Future<void> _exportEquipmentsToExcel(List<Equipment> equipmentsToExport) async {
    try {
      if (equipmentsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No equipments to export.')),
        );
        return;
      }
      debugPrint('📊 [Excel Export] Exporting ${equipmentsToExport.length} equipments.');

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Equipments'];

      // Add Heading at the top
      final title = widget.employeeRole == 'HOD' 
          ? 'DEPARTMENTAL EQUIPMENT REPORT - ${widget.employeeDepartment?.toUpperCase()}'
          : 'MY ASSIGNED EQUIPMENT REPORT - ${widget.employeeId.toUpperCase()}';
          
      sheetObject.insertRowIterables([
        TextCellValue(title),
      ], 0);
      
      // Add a blank row for spacing
      sheetObject.insertRowIterables([TextCellValue('')], 1);

      // Add headers at row 2
      List<String> headers = [
        'ID', 'Name', 'Type', 'Group', 'Mode', 'Manufacturer', 'Serial No',
        'Department', 'Status', 'Service Status', 'Warranty Upto',
        'Purchased Cost', 'Installation Date', 'Assigned Employee ID',
        'Has Warranty', 'College ID',
      ];
      sheetObject.insertRowIterables(headers.map((e) => TextCellValue(e)).toList(), 2);

      // Add data rows starting from row 3
      for (int i = 0; i < equipmentsToExport.length; i++) {
        final equipment = equipmentsToExport[i];
        List<CellValue?> rowData = [
          TextCellValue(equipment.id),
          TextCellValue(equipment.name),
          TextCellValue(equipment.type),
          TextCellValue(equipment.group),
          TextCellValue(equipment.mode),
          TextCellValue(equipment.manufacturer),
          TextCellValue(equipment.serialNo),
          TextCellValue(equipment.department),
          TextCellValue(equipment.status),
          TextCellValue(equipment.service),
          TextCellValue(equipment.warrantyUpto != null ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!) : ''),
          DoubleCellValue(equipment.purchasedCost),
          TextCellValue(DateFormat('yyyy-MM-dd').format(equipment.installationDate)),
          TextCellValue(equipment.assignedEmployeeIds != null ? equipment.assignedEmployeeIds!.join(', ') : ''),
          BoolCellValue(equipment.hasWarranty),
          TextCellValue(equipment.collegeId),
        ];
        sheetObject.insertRowIterables(rowData, i + 3);
      }

      List<int>? excelBytes = excel.encode();
      if (excelBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to encode Excel file.')),
        );
        return;
      }

      final String fileName = widget.employeeRole == 'HOD'
          ? 'dept_equipments_${widget.employeeDepartment}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx'
          : 'my_equipments_${widget.employeeId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        downloadFileWeb(context, Uint8List.fromList(excelBytes), fileName);
      } else {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Equipments Excel File',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          final file = io.File(outputFile);
          await file.writeAsBytes(excelBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipments exported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final allCollegeEquipments = equipmentProvider.equipments.where((e) => e.collegeId == widget.collegeName).toList();
    
    // Filtering logic: HOD sees all equipment in their department. 
    // Others only see equipment explicitly assigned to them.
    final List<Equipment> myEquipments;
    if (widget.employeeRole == 'HOD' && widget.employeeDepartment != null) {
      myEquipments = allCollegeEquipments.where((e) => e.department == widget.employeeDepartment).toList();
    } else {
      myEquipments = allCollegeEquipments.where((e) => e.assignedEmployeeIds != null && e.assignedEmployeeIds!.contains(widget.employeeId)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeRole == 'HOD' ? 'Departmental Equipments' : 'My Assigned Equipments'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: () => _exportEquipmentsToExcel(myEquipments),
          ),
        ],
      ),
      body: ManagementListWidget(
        items: myEquipments.map((equipment) => ManagementListItem(
          id: equipment.id,
          title: equipment.name,
          subtitle: equipment.department,
          icon: Icons.devices_other,
          iconColor: const Color(0xFF2563EB),
          badge: equipment.status,
          badgeColor: equipment.status == 'Working' ? Colors.green : Colors.red,
          actions: [
            ManagementAction(
              label: 'View',
              icon: Icons.remove_red_eye,
              color: const Color(0xFF2563EB),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ModernDetailsDialog(
                    title: 'Equipment Details',
                    details: [
                      DetailRow(label: 'Name', value: equipment.name),
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
                      DetailRow(label: 'College ID', value: equipment.collegeId),
                      DetailRow(label: 'Assigned To', value: equipment.assignedEmployeeIds?.join(', ') ?? 'Unassigned'),
                    ],
                    qrCodeWidget: QrImageView(
                      data: equipment.id,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              },
            ),
            ManagementAction(
              label: 'Toggle',
              icon: equipment.status == 'Working' ? Icons.check_circle : Icons.error_outline,
              color: equipment.status == 'Working' ? Colors.green : Colors.red,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status changed to $newStatus')),
                );
              },
            ),
            // ONLY show Unassign if it's actually assigned to the current user
            if (equipment.assignedEmployeeIds != null && equipment.assignedEmployeeIds!.contains(widget.employeeId))
              ManagementAction(
                label: 'Unassign',
                icon: Icons.person_remove,
                color: const Color(0xFFDC2626),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Unassignment'),
                      content: const Text('Are you sure you want to unassign this equipment from yourself?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Unassign')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final newList = List<String>.from(equipment.assignedEmployeeIds ?? []);
                    newList.remove(widget.employeeId);
                    final updatedEquipment = equipment.copyWith(assignedEmployeeIds: newList);
                    await equipmentProvider.updateEquipment(equipment.id, updatedEquipment, notificationProvider: Provider.of<NotificationProvider>(context, listen: false), updatedByRole: 'employee');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Equipment unassigned.')),
                    );                  }
                },
              ),
          ],
        )).toList(),
        emptyMessage: widget.employeeRole == 'HOD' 
          ? 'No equipment found in your department.' 
          : 'You have no equipment assigned.',
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context, List<Equipment> allCollegeEquipments) {
    final unassignedEquipments = allCollegeEquipments.where((e) => e.assignedEmployeeIds == null || e.assignedEmployeeIds!.isEmpty).toList();
    Equipment? selectedEquipment;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Equipment to Yourself'),
              content: SizedBox(
                width: double.maxFinite,
                child: unassignedEquipments.isEmpty
                    ? const Text('No unassigned equipment available in your college.')
                    : DropdownButtonFormField<Equipment>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Select Equipment'),
                        initialValue: selectedEquipment,
                        selectedItemBuilder: (BuildContext context) {
                          return unassignedEquipments.map((equipment) {
                            return Text(
                              '${equipment.name} (ID: ${equipment.id})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          }).toList();
                        },
                        items: unassignedEquipments.map((equipment) {
                          return DropdownMenuItem<Equipment>(
                            value: equipment,
                            child: Text(
                              '${equipment.name} (ID: ${equipment.id})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedEquipment = value;
                          });
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedEquipment == null ? null : () async {
                    final equipmentToAssign = selectedEquipment!;
                    final newList = List<String>.from(equipmentToAssign.assignedEmployeeIds ?? []);
                    if (!newList.contains(widget.employeeId)) {
                      newList.add(widget.employeeId);
                    }
                    final updatedEquipment = equipmentToAssign.copyWith(assignedEmployeeIds: newList);
                    
                    await Provider.of<EquipmentProvider>(context, listen: false)
                        .updateEquipment(equipmentToAssign.id, updatedEquipment);

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Equipment assigned successfully.')),
                    );
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
