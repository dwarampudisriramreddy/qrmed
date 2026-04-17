import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supreme_institution/providers/equipment_provider.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';

class CollegeEquipmentsWidget extends StatelessWidget {
  final String collegeName;

  const CollegeEquipmentsWidget({super.key, required this.collegeName});

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final collegeEquipments = equipmentProvider.equipments
        .where((e) => e.collegeId == collegeName)
        .toList();
    
    debugPrint('🔍 [CollegeEquipmentsWidget] College ID: $collegeName');
    debugPrint('🔍 [CollegeEquipmentsWidget] Total Equipments in Provider: ${equipmentProvider.equipments.length}');
    debugPrint('🔍 [CollegeEquipmentsWidget] Filtered College Equipments: ${collegeEquipments.length}');
    if (collegeEquipments.isNotEmpty) {
      debugPrint('🔍 [CollegeEquipmentsWidget] First Equipment: ${collegeEquipments.first.name}');
    }

    return ManagementListWidget(
      items: collegeEquipments.map((equipment) {
        final isNotWorking = equipment.status != 'Working';
        return ManagementListItem(
          id: equipment.id,
          title: equipment.name,
          subtitle: equipment.department,
          icon: Icons.devices_other,
          iconColor: isNotWorking ? Colors.red : const Color(0xFF2563EB),
          badge: equipment.status,
          badgeColor: equipment.status == 'Working' ? Colors.green : (equipment.status == 'Under Maintenance' ? Colors.orange : Colors.red),
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
                ),
              );
            },
          ),
        ],
        );
      }).toList(),
      emptyMessage: 'No equipments found for this college.',
    );
  }
}
