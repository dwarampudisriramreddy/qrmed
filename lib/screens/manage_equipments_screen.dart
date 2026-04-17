import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import '../models/equipment.dart';
import '../models/app_notification.dart';
import '../providers/equipment_provider.dart';
import '../providers/employee_provider.dart';
import '../models/college.dart';
import '../providers/college_provider.dart';
import '../models/department.dart';
import '../providers/department_provider.dart';
import '../models/employee.dart';
import '../providers/notification_provider.dart';
import '../providers/requirements_provider.dart';
import '../widgets/management_list_widget.dart';
import '../widgets/modern_details_dialog.dart';
import '../utils/web_download_stub.dart'; // Import the conditional stub

class ManageEquipmentsScreen extends StatefulWidget { // Changed from ManageProductsScreen
  final String collegeName;
  const ManageEquipmentsScreen({super.key, required this.collegeName}); // Changed from ManageProductsScreen

  @override
  _ManageEquipmentsScreenState createState() => _ManageEquipmentsScreenState(); // Changed from _ManageProductsScreenState
}

class _ManageEquipmentsScreenState extends State<ManageEquipmentsScreen> { // Changed from _ManageProductsScreenState
  // Controllers
  final _searchController = TextEditingController();
  final _equipmentNameController = TextEditingController();
  final _equipmentTypeController = TextEditingController();
  final _equipmentGroupController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialNoController = TextEditingController();
  final _statusController = TextEditingController();
  final _serviceStatusController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _purchasedValueController = TextEditingController();
  final _verifiedByController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _equipmentNameFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  DateTime? _purchasedDate;
  DateTime? _verifiedDate;
  String _generatedId = '';
  final Map<String, GlobalKey> _stickerKeys = {};
  Uint8List? _logoBytes;
  Uint8List? _supremeLogoBytes;

  List<String> _equipmentNames = []; // Added for dropdown
  String? _selectedEquipment; // Added for dropdown
  String? _selectedDepartment; // Track selected department for employee dropdown
  List<String> _selectedEmployeeIds = []; // Multi-select employee assignment
  String? _selectedDepartmentFilter; // Added for search filter
  String? _selectedEquipmentNameFilter; // Added for interactive chip filtering
  String? _selectedStatusFilter; // Added for interactive status filtering
  College? _college; // Added to store college data

  Future<void> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/favicon.png');
      final bytes = data.buffer.asUint8List();
      if (mounted) {
        setState(() {
          _logoBytes = bytes;
        });
        debugPrint('✅ favicon.png bytes loaded in ManageEquipments');
      }
    } catch (e) {
      debugPrint('❌ Error loading favicon.png bytes in ManageEquipments: $e');
    }
  }

  Future<void> _loadSupremeLogo() async {
    try {
      final data = await rootBundle.load('assets/supreme_logo_transparent.png');
      final bytes = data.buffer.asUint8List();
      if (mounted) {
        setState(() {
          _supremeLogoBytes = bytes;
        });
        debugPrint('✅ supreme_logo_transparent.png bytes loaded in ManageEquipments');
      }
    } catch (e) {
      debugPrint('❌ Error loading supreme_logo_transparent.png bytes in ManageEquipments: $e');
    }
  }

  Future<void> _exportStickerAsPng(Equipment equipment) async {
    try {
      debugPrint('🎨 [STICKER] Starting export for equipment: ${equipment.id} - ${equipment.name}');
      
      if (!_stickerKeys.containsKey(equipment.id)) {
        debugPrint('❌ [STICKER] Key not found for equipment: ${equipment.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Sticker not found. Please refresh and try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] Key found for equipment: ${equipment.id}');
      final key = _stickerKeys[equipment.id]!;
      
      debugPrint('⏳ [STICKER] Waiting for widget to fully render...');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) {
        debugPrint('❌ [STICKER] Widget not mounted');
        return;
      }
      
      if (key.currentContext == null) {
        debugPrint('❌ [STICKER] Current context is null for equipment: ${equipment.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Sticker not ready. Please try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] Current context found');
      final RenderObject? renderObject = key.currentContext!.findRenderObject();
      
      if (renderObject == null) {
        debugPrint('❌ [STICKER] RenderObject is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not find render object.')),
        );
        return;
      }

      final boundary = renderObject as RenderRepaintBoundary?;
      
      if (boundary == null) {
        debugPrint('❌ [STICKER] RenderRepaintBoundary is null');
        debugPrint('📊 [STICKER] Render object type: ${renderObject.runtimeType}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not render sticker. Please try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] RenderRepaintBoundary found');
      debugPrint('📐 [STICKER] Converting to image with 2x pixelRatio...');
      
      // Use a more aggressive wait strategy
      ui.Image? image;
      int attempts = 0;
      const maxAttempts = 5;
      
      while (image == null && attempts < maxAttempts) {
        try {
          debugPrint('🔄 [STICKER] Attempt ${attempts + 1}/$maxAttempts to capture image');
          
          // Wait for frame and extra time
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 150));
          
          if (!mounted) {
            debugPrint('❌ [STICKER] Widget unmounted');
            return;
          }
          
          // Check if boundary is in a valid state
          debugPrint('✅ [STICKER] Boundary state: size=${boundary.size}, hasSize=${boundary.hasSize}');
          
          image = await boundary.toImage(pixelRatio: 2.0);
          break;
        } catch (e) {
          attempts++;
          debugPrint('⚠️ [STICKER] Attempt $attempts failed: $e');
          
          if (attempts >= maxAttempts) {
            debugPrint('❌ [STICKER] All attempts failed');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Could not export sticker after multiple attempts.')),
              );
            }
            return;
          }
          
          // Wait longer before retry
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      if (image == null) {
        debugPrint('❌ [STICKER] Failed to create image');
        return;
      }
      
      debugPrint('🔄 [STICKER] Converting image to bytes...');
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('❌ [STICKER] ByteData conversion failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not process image. Please try again.')),
        );
        return;
      }

      debugPrint('✅ [STICKER] ByteData created: ${byteData.lengthInBytes} bytes');

      final bytes = byteData.buffer.asUint8List();
      final fileName = 'equipment_${equipment.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      if (kIsWeb) {
        debugPrint('🌐 [STICKER] Web platform detected - triggering download...');
        downloadFileWeb(context, bytes, fileName); // Use the conditionally imported function
        return;
      }

      if (io.Platform.isAndroid || io.Platform.isIOS) {
        debugPrint('📱 [STICKER] Mobile platform detected - saving to Downloads folder...');
        try {
          final directory = await getDownloadsDirectory(); // Get Downloads directory
          if (directory == null) {
            // Fallback to application documents directory if downloads directory not available
            final appDocDir = await getApplicationDocumentsDirectory();
            final filePath = '${appDocDir.path}/$fileName';
            final file = io.File(filePath);
            await file.writeAsBytes(bytes);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sticker saved to: $filePath (Downloads folder not found, saved to app documents)')),
            );
          } else {
            final filePath = '${directory.path}/$fileName';
            final file = io.File(filePath);
            await file.writeAsBytes(bytes);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sticker saved to: $filePath')),
            );
          }
        } catch (e) {
          debugPrint('Error saving to Downloads: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving sticker to Downloads: $e')),
                      );        }
      } else { // Desktop platforms (Windows, macOS, Linux)
        debugPrint('🖥️ [STICKER] Desktop platform detected - saving to file...');
        String? defaultDownloadPath;
        try {
          final downloadsDir = await getDownloadsDirectory();
          defaultDownloadPath = downloadsDir?.path;
        } catch (e) {
          debugPrint('Could not get downloads directory: $e');
        }

        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Equipment Sticker',
          fileName: fileName,
          type: FileType.image,
          allowedExtensions: ['png'],
          initialDirectory: defaultDownloadPath,
        );
        
        if (savePath != null) {
          debugPrint('💾 [STICKER] Saving to: $savePath');
          final file = io.File(savePath);
          await file.writeAsBytes(bytes);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sticker saved to: $savePath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save cancelled.')),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [STICKER] EXCEPTION: $e');
      debugPrint('📍 [STICKER] STACK TRACE:\n$stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting sticker: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _loadSupremeLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEquipments();
      _loadCollegeDataAndEquipmentNames(); // NEW: Load college data and equipment names
      
      // Precache the logo to ensure it's ready for sticker generation
      precacheImage(const AssetImage('assets/favicon.png'), context);
      precacheImage(const AssetImage('assets/supreme_logo_transparent.png'), context);
    });
  }

  String _normalizeEquipmentName(String name) {
    // Remove content in parentheses like "(Supragingival)" or "(x2)"
    String normalized = name.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    
    if (normalized.isEmpty) return name;

    // Convert to Title Case
    List<String> words = normalized.toLowerCase().split(' ');
    words = words.map((word) {
      if (word.isEmpty) return word;
      if (word == '&' || word == 'and') return word;
      return word[0].toUpperCase() + word.substring(1);
    }).toList();
    
    normalized = words.join(' ');

    // Handle specific pluralization/variants noticed in data
    if (normalized == 'Dental Chairs And Unit') normalized = 'Dental Chairs And Units';
    if (normalized == 'Extraction Forceps Sets') normalized = 'Extraction Forceps Set';
    
    return normalized;
  }

  // NEW: Method to load college data and populate _equipmentNames
  Future<void> _loadCollegeDataAndEquipmentNames() async {
    final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
    final requirementsProvider = Provider.of<RequirementsProvider>(context, listen: false);
    
    print('ManageEquipmentsScreen: Accessed providers to load equipment names.');
    try {
      _college = collegeProvider.colleges.firstWhere((c) => c.id == widget.collegeName);
      print('ManageEquipmentsScreen: College found: ${_college!.name}, type: ${_college!.type}');
      
      // Normalize college type to match keys in requirements data
      String normalizedCollegeType = '';
      final trimmedCollegeType = _college!.type.trim().toUpperCase();
      if (trimmedCollegeType == 'DENTAL' || trimmedCollegeType == 'BDS') {
        normalizedCollegeType = 'BDS';
      } else if (trimmedCollegeType == 'MEDICAL' || trimmedCollegeType == 'MBBS') {
        normalizedCollegeType = 'MBBS';
      }

      final masterList = requirementsProvider.getUniqueEquipmentsForCourse(normalizedCollegeType);

      setState(() {
        _equipmentNames = masterList;
        _equipmentNames.sort();
        print('ManageEquipmentsScreen: Final loaded equipment names from Master List: $_equipmentNames');
      });

    } catch (e) {
      print('ManageEquipmentsScreen: College not found for name: ${widget.collegeName}. Error: $e');
      _college = null;
    }
  }

  Future<void> _fetchEquipments() async { // Changed from _fetchProducts
    await Provider.of<EquipmentProvider>(context, listen: false).fetchEquipments(); // Changed from ProductProvider and fetchProducts
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _equipmentNameController.dispose();
    _equipmentTypeController.dispose();
    _equipmentGroupController.dispose();
    _deviceTypeController.dispose();
    _manufacturerController.dispose();
    _serialNoController.dispose();
    _statusController.dispose();
    _serviceStatusController.dispose();
    _warrantyController.dispose();
    _purchasedValueController.dispose();
    _verifiedByController.dispose();
    _quantityController.dispose();
    _equipmentNameFocusNode.dispose();
    super.dispose();
  }

  void _fillFormWithEquipment(Equipment equipment) {
    _selectedEquipment = equipment.name; // Set the selected equipment for the dropdown
    _equipmentNameController.text = equipment.name;
    _equipmentTypeController.text = equipment.type;
    _equipmentGroupController.text = equipment.group;
    _deviceTypeController.text = equipment.mode;
    _manufacturerController.text = equipment.manufacturer;
    _serialNoController.text = equipment.serialNo;
    _selectedDepartment = equipment.department;
    _statusController.text = equipment.status;
    _serviceStatusController.text = equipment.service;
    _warrantyController.text = equipment.warrantyUpto != null ? DateFormat('yyyy-MM-dd').format(equipment.warrantyUpto!) : '';
    _purchasedValueController.text = equipment.purchasedCost.toString();
    _purchasedDate = equipment.installationDate;
    _selectedEmployeeIds = List<String>.from(equipment.assignedEmployeeIds ?? []);
    _generatedId = equipment.id;

    // Auto-select HOD of the selected department if not already selected
    if (_selectedDepartment != null) {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final hods = employeeProvider.employees.where((emp) => 
        emp.collegeId == widget.collegeName && 
        emp.department == _selectedDepartment && 
        emp.role == 'HOD'
      ).toList();
      
      for (var hod in hods) {
        if (!_selectedEmployeeIds.contains(hod.id)) {
          _selectedEmployeeIds.add(hod.id);
        }
      }
    }
  }

  void _clearForm() {
    _equipmentNameController.clear();
    _equipmentTypeController.clear();
    _equipmentGroupController.clear();
    _deviceTypeController.clear();
    _manufacturerController.clear();
    _serialNoController.clear();
    _statusController.clear();
    _serviceStatusController.clear();
    _warrantyController.clear();
    _purchasedValueController.clear();
    _verifiedByController.clear();
    _quantityController.text = '1';
    _purchasedDate = null;
    _verifiedDate = null;
    _generatedId = '';
    _selectedEquipment = null; // Clear selected equipment
    _selectedDepartment = null; // Clear selected department
    _selectedEmployeeIds = [];
  }

  Future<void> _showAddEquipmentDialog() async { // Changed from _showAddProductDialog
    // Fetch departments and employees
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    
    await departmentProvider.fetchDepartmentsForCollege(widget.collegeName);
    await employeeProvider.fetchEmployees();

    _clearForm();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Equipment'), // Changed from Add Product
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: _buildEquipmentForm(dialogSetState: setDialogState), // Changed from _buildProductForm
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  
                  final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
                  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                  
                  final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
                  
                  List<Equipment> equipmentsToAdd = [];
                  String collegeCode = _college?.collegeCode ?? '000';
                  
                  for (int i = 0; i < quantity; i++) {
                    // We need to be careful with ID generation in a loop.
                    // generateNextEquipmentId uses the current _equipments list.
                    // To handle multiple in a loop correctly, we should get the next ID,
                    // and for subsequent ones, increment it manually or update our local list.
                    
                    String nextId;
                    if (equipmentsToAdd.isEmpty) {
                      nextId = equipmentProvider.generateNextEquipmentId(collegeCode);
                    } else {
                      // Get the last added ID and increment it
                      String lastId = equipmentsToAdd.last.id;
                      int lastSeq = int.parse(lastId.substring(3));
                      nextId = collegeCode + (lastSeq + 1).toString().padLeft(4, '0');
                    }

                    // Check for collisions with existing equipments not in our current batch
                    if (equipmentProvider.equipments.any((e) => e.id == nextId)) {
                      // This might happen if someone else added equipment or if there's a gap.
                      // For simplicity, we can try to find the next available ID by incrementing until free.
                      int currentSeq = int.parse(nextId.substring(3));
                      while (equipmentProvider.equipments.any((e) => e.id == nextId)) {
                        currentSeq++;
                        nextId = collegeCode + currentSeq.toString().padLeft(4, '0');
                      }
                    }

                    equipmentsToAdd.add(Equipment(
                      id: nextId,
                      qrcode: nextId,
                      name: _selectedEquipment ?? _equipmentNameController.text.trim(),
                      type: _equipmentTypeController.text.trim(),
                      group: _equipmentGroupController.text.trim(),
                      mode: _deviceTypeController.text.trim(),
                      manufacturer: _manufacturerController.text.trim(),
                      serialNo: _serialNoController.text.trim(),
                      department: _selectedDepartment ?? '',
                      status: _statusController.text.trim(),
                      service: _serviceStatusController.text.trim(),
                      warrantyUpto: _warrantyController.text.isNotEmpty ? DateTime.tryParse(_warrantyController.text) : null,
                      purchasedCost: double.tryParse(_purchasedValueController.text) ?? 0.0,
                      installationDate: _purchasedDate ?? DateTime.now(),
                      assignedEmployeeIds: _selectedEmployeeIds,
                      hasWarranty: _warrantyController.text.isNotEmpty,
                      collegeId: widget.collegeName,
                    ));
                  }
                  
                  await equipmentProvider.addMultipleEquipments(equipmentsToAdd);
                  
                  // Optional: add notifications for "Not Working" items if needed.
                  // (The original code only added one notification for addEquipment)
                  if (notificationProvider != null) {
                    for (var eq in equipmentsToAdd) {
                      if (eq.status == 'Not Working') {
                        await notificationProvider.addNotification(AppNotification(
                          id: '',
                          title: 'New Failure Reported',
                          message: 'College ${eq.collegeId} added: ${eq.name} (ID: ${eq.id}) in ${eq.department} as Not Working.',
                          timestamp: DateTime.now(),
                          targetUserId: 'admin',
                          equipmentId: eq.id,
                        ));
                      }
                    }
                  }

                  setState(() {});
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$quantity equipment(s) added successfully.')),
                  );
                },
                child: const Text('Add'),
              ),
        ],
          );
        },
      ),
    );
  }

  Future<void> _editEquipment(Equipment oldEquipment) async { // Changed from _editProduct(Product oldProduct)
    // Fetch departments and employees
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    
    await departmentProvider.fetchDepartmentsForCollege(widget.collegeName);
    await employeeProvider.fetchEmployees();

    _fillFormWithEquipment(oldEquipment); // Changed from _fillFormWithProduct
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Equipment'), // Changed from Edit Product
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: _buildEquipmentForm(dialogSetState: setDialogState, isEditing: true), // Changed from _buildProductForm
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
                  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                  final updatedEquipment = Equipment( // Changed from updatedProduct = Product
                    id: oldEquipment.id,
                    qrcode: oldEquipment.qrcode,
                    name: _selectedEquipment ?? _equipmentNameController.text.trim(),
                    type: _equipmentTypeController.text.trim(),
                    group: _equipmentGroupController.text.trim(),
                    mode: _deviceTypeController.text.trim(),
                    manufacturer: _manufacturerController.text.trim(),
                    serialNo: _serialNoController.text.trim(),
                    department: _selectedDepartment ?? '',
                    status: _statusController.text.trim(),
                    service: _serviceStatusController.text.trim(),
                    warrantyUpto: _warrantyController.text.isNotEmpty ? DateTime.tryParse(_warrantyController.text) : null,
                    purchasedCost: double.tryParse(_purchasedValueController.text) ?? 0.0,
                    installationDate: _purchasedDate ?? DateTime.now(),
                    assignedEmployeeIds: _selectedEmployeeIds,
                    hasWarranty: _warrantyController.text.isNotEmpty,
                    collegeId: widget.collegeName,
                  );
                  await equipmentProvider.updateEquipment(
                    oldEquipment.id, 
                    updatedEquipment,
                    notificationProvider: notificationProvider,
                    updatedByRole: 'college',
                  ); // Changed from ProductProvider and updateProduct
                  setState(() {});
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Equipment updated successfully.')), // Changed from Product updated successfully
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteEquipment(String id) async { // Changed from _deleteProduct(String id)
    await Provider.of<EquipmentProvider>(context, listen: false).deleteEquipment(id); // Changed from ProductProvider and deleteProduct
    setState(() {});
  }

  Future<void> _uploadExcel() async {
    try {
      // Show warning dialog before proceeding to file picker
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excel Upload Guidelines'),
          content: const Text(
            'Your Excel file should have the following columns for equipment data:\n\n'
            '- "equipment name" (required)\n'
            '- "department" (required)\n'
            '- "status" (required)\n'
            '- "type" (optional)\n'
            '- "manufacturer" (optional)\n'
            '- "serial no" (optional)\n'
            '\nOther columns are also optional.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        // User cancelled the operation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel upload cancelled.')),
        );
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List bytes = result.files.single.bytes!;
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          // Assuming first row is header
          List<String> headers = sheet.rows.first.map((cell) => cell?.value?.toString().toLowerCase().trim() ?? '').toList();

          int nameIndex = headers.indexOf('equipment name');
          int departmentIndex = headers.indexOf('department');
          int statusIndex = headers.indexOf('status');

          if (nameIndex == -1 || departmentIndex == -1 || statusIndex == -1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Excel file must contain "Equipment Name", "Department", and "Status" columns.')),
            );
            return;
          }

          List<Equipment> newEquipments = [];
          final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
          String startId = equipmentProvider.generateNextEquipmentId(_college?.collegeCode ?? '000');
          String collegeCode = startId.substring(0, 3);
          int nextSeq = int.parse(startId.substring(3));

          for (int i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.every((cell) => cell?.value == null)) continue; // Skip empty rows

            String name = row[nameIndex]?.value?.toString().trim() ?? '';
            String department = row[departmentIndex]?.value?.toString().trim() ?? '';
            String status = row[statusIndex]?.value?.toString().trim() ?? '';

            if (name.isEmpty || department.isEmpty || status.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Skipping row ${i + 1}: Missing required data.')),
              );
              continue;
            }

            String currentId = collegeCode + (nextSeq++).toString().padLeft(4, '0');

            newEquipments.add(Equipment(
              id: currentId,
              qrcode: currentId,
              name: name,
              type: '', // Optional, set default or parse if available
              group: '', // Optional
              mode: '', // Optional
              manufacturer: '', // Optional
              serialNo: '', // Optional
              department: department,
              status: status,
              service: '', // Optional
              warrantyUpto: null, // Optional
              purchasedCost: 0.0, // Optional
              installationDate: DateTime.now(), // Default to now
              assignedEmployeeIds: [], // Optional
              hasWarranty: false, // Optional
              collegeId: widget.collegeName,
            ));
          }

          if (newEquipments.isNotEmpty) {
            final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
            for (var equipment in newEquipments) {
              await equipmentProvider.addEquipment(equipment, notificationProvider: notificationProvider);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${newEquipments.length} equipments added successfully!')),
            );
            _fetchEquipments(); // Refresh the list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No valid equipments found in the Excel file.')),
            );
          }
          break; // Process only the first sheet
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File picking cancelled or no file selected.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading Excel: $e')),
        );
      }
    }
  }

  void _showMultiSelectEmployees(List<Employee> departmentEmployees, StateSetter dialogSetState) async {
    final List<String>? results = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setInternalState) {
            return AlertDialog(
              title: const Text('Assign to Employees'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: departmentEmployees.map((employee) {
                    final isChecked = _selectedEmployeeIds.contains(employee.id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text('${employee.name} (${employee.role})'),
                      onChanged: (bool? value) {
                        setInternalState(() {
                          if (value == true) {
                            _selectedEmployeeIds.add(employee.id);
                          } else {
                            _selectedEmployeeIds.remove(employee.id);
                          }
                        });
                        dialogSetState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context, _selectedEmployeeIds),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (results != null) {
      dialogSetState(() {
        _selectedEmployeeIds = results;
      });
    }
  }

  Widget _buildEquipmentForm({StateSetter? dialogSetState, bool isEditing = false}) { // Changed from _buildProductForm
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RawAutocomplete<String>(
            textEditingController: _equipmentNameController,
            focusNode: _equipmentNameFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _equipmentNames.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _selectedEquipment = selection;
                _equipmentNameController.text = selection;
              });
              dialogSetState?.call(() {
                _selectedEquipment = selection;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Equipment Name*',
                  hintText: 'Type to search...',
                  suffixIcon: Icon(Icons.search, size: 20),
                ),
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an equipment name.';
                  }
                  if (!_equipmentNames.contains(value)) {
                    return 'Please select from the suggestions.';
                  }
                  return null;
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: SizedBox(
                    width: 300, // Fixed width for the suggestions overlay
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return ListTile(
                            title: Text(option, style: const TextStyle(fontSize: 14)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (!isEditing)
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity', hintText: 'Enter number of equipments to add'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final q = int.tryParse(v);
                if (q == null || q <= 0) return 'Must be a positive number';
                return null;
              },
            ),
          TextFormField(
            controller: _equipmentTypeController,
            decoration: const InputDecoration(labelText: 'Equipment Type'),
          ),
          TextFormField(
            controller: _equipmentGroupController,
            decoration: const InputDecoration(labelText: 'Equipment Group'),
          ),
          TextFormField(
            controller: _deviceTypeController,
            decoration: const InputDecoration(labelText: 'Device Type'),
          ),
          TextFormField(
            controller: _manufacturerController,
            decoration: const InputDecoration(labelText: 'Manufacturer'),
          ),
          TextFormField(
            controller: _serialNoController,
            decoration: const InputDecoration(labelText: 'Serial No'),
          ),
          // Department dropdown from available departments
          Consumer<DepartmentProvider>(
            builder: (context, departmentProvider, _) {
              // Get college ID from widget.collegeName
              final departments = departmentProvider.getDepartmentsForCollege(widget.collegeName);
              
              if (departments.isEmpty) {
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: null,
                  decoration: const InputDecoration(
                    labelText: 'Department*',
                    hintText: 'No Departments Available',
                  ),
                  hint: const Text('No Departments Available'),
                  items: const [],
                  onChanged: null,
                );
              }
              
              // Ensure unique department names to avoid "Duplicate value" error in Dropdown
              final List<String> uniqueDeptNames = departments.map((d) {
                return d.subSelectionType != null ? "${d.name} (${d.subSelectionType})" : d.name;
              }).toSet().toList()..sort();
              
              // Ensure _selectedDepartment is valid for the items list
              if (_selectedDepartment != null && !uniqueDeptNames.contains(_selectedDepartment)) {
                uniqueDeptNames.add(_selectedDepartment!);
              }

              return DropdownButtonFormField<String>(
                isExpanded: true,
                value: uniqueDeptNames.contains(_selectedDepartment) ? _selectedDepartment : null,
                decoration: const InputDecoration(labelText: 'Department*'),
                hint: const Text('Select Department'),
                selectedItemBuilder: (BuildContext context) {
                  return uniqueDeptNames.map((String name) {
                    return Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: uniqueDeptNames.map((String name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  debugPrint('🔵 [Dialog] Department changed to: $newValue');
                  
                  // Update class member
                  _selectedDepartment = newValue;
                  _selectedEmployeeIds = [];
                  
                  if (newValue != null) {
                    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
                    final hods = employeeProvider.employees.where((emp) => 
                      emp.collegeId == widget.collegeName && 
                      emp.department == newValue && 
                      emp.role == 'HOD'
                    ).toList();
                    if (hods.isNotEmpty) {
                      _selectedEmployeeIds = hods.map((h) => h.id).toList();
                    }
                  }

                  // Force rebuild of parent screen and dialog
                  setState(() {});
                  dialogSetState?.call(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a department';
                  }
                  return null;
                },
              );
            },
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _statusController.text.isNotEmpty ? _statusController.text : null,
            decoration: const InputDecoration(labelText: 'Status*'),
            hint: const Text('Select Status'),
            selectedItemBuilder: (BuildContext context) {
              return ['Working', 'Not Working', 'Under Maintenance', 'Standby'].map((String status) {
                return Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              }).toList();
            },
            items: ['Working', 'Not Working', 'Under Maintenance', 'Standby']
                .map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              _statusController.text = newValue ?? '';
              setState(() {});
              dialogSetState?.call(() {});
            },
            validator: (value) => (value == null || value.isEmpty) ? 'Please select a status.' : null,
          ),
          TextFormField(
            controller: _serviceStatusController,
            decoration: const InputDecoration(labelText: 'Service Status'),
          ),
          TextFormField(
            controller: _warrantyController,
            decoration: const InputDecoration(labelText: 'Warranty (YYYY-MM-DD)'),
          ),
          TextFormField(
            controller: _purchasedValueController,
            decoration: const InputDecoration(labelText: 'Purchased Value'),
            keyboardType: TextInputType.number,
          ),
          ListTile(
            title: Text(_purchasedDate == null ? 'Purchased Date' : 'Purchased: ${DateFormat('yyyy-MM-dd').format(_purchasedDate!)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                _purchasedDate = date;
                setState(() {});
                dialogSetState?.call(() {});
              }
            },
          ),
          // Multi-select Employee assignment - filtered by selected department
          if (dialogSetState != null)
          Builder(
            key: ValueKey('employee-multiselect-${_selectedDepartment ?? 'no-dept'}'),
            builder: (context) {
              return Consumer<EmployeeProvider>(
                builder: (context, employeeProvider, _) {
                  // Get employees for this college
                  final collegeEmployees = employeeProvider.employees
                      .where((emp) => emp.collegeId == widget.collegeName)
                      .toList();
                  
                  // Filter employees by selected department
                  final selectedDept = _selectedDepartment ?? '';
                  final departmentEmployees = selectedDept.isNotEmpty
                      ? collegeEmployees
                          .where((emp) => emp.department == selectedDept)
                          .toList()
                      : <Employee>[];
                  
                  String displayText;
                  if (selectedDept.isEmpty) {
                    displayText = 'Select Department First';
                  } else if (departmentEmployees.isEmpty) {
                    displayText = 'No Employees in Selected Department';
                  } else if (_selectedEmployeeIds.isEmpty) {
                    displayText = 'Select Employees (Optional)';
                  } else {
                    final names = departmentEmployees
                        .where((e) => _selectedEmployeeIds.contains(e.id))
                        .map((e) => e.name)
                        .join(', ');
                    displayText = names;
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign to Employees',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: (selectedDept.isNotEmpty && departmentEmployees.isNotEmpty)
                            ? () => _showMultiSelectEmployees(departmentEmployees, dialogSetState)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    color: (selectedDept.isNotEmpty && departmentEmployees.isNotEmpty)
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text(_verifiedDate == null ? 'Verified Date' : 'Verified: ${DateFormat('yyyy-MM-dd').format(_verifiedDate!)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                _verifiedDate = date;
                setState(() {});
                dialogSetState?.call(() {});
              }
            },
          ),
          TextFormField(
            controller: _verifiedByController,
            decoration: const InputDecoration(labelText: 'Verified By'),
          ),
          const SizedBox(height: 16),
          if (_generatedId.isNotEmpty) ...[
            Text(
              'Generated ID: $_generatedId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: _generatedId,
                version: QrVersions.auto,
                size: 100,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Function to delete all equipments for the college
  Future<void> _deleteAllEquipments() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Equipments'),
        content: Text('Are you sure you want to delete ALL equipments for ${widget.collegeName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
        // This method will need to be implemented in equipment_provider.dart
        await equipmentProvider.deleteAllEquipmentsForCollege(widget.collegeName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All equipments for ${widget.collegeName} deleted successfully!')),
        );
        _fetchEquipments(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting all equipments: $e')),
        );
      }
    }
  }

  // NEW: Function to export equipments to Excel
  Future<void> _exportEquipmentsToExcel({List<Equipment>? customList}) async {
    try {
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      
      final List<Equipment> equipmentsToExport;
      if (customList != null) {
        equipmentsToExport = customList;
      } else {
        equipmentsToExport = equipmentProvider.equipments
            .where((e) => e.collegeId.trim() == widget.collegeName.trim())
            .toList();
      }

      if (equipmentsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No equipments to export.')),
        );
        return;
      }
      debugPrint('📊 [Excel Export] Exporting ${equipmentsToExport.length} equipments.');

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Equipments'];

      // Add College Name Heading at the top
      sheetObject.insertRowIterables([
        TextCellValue('EQUIPMENT REPORT - ${widget.collegeName.toUpperCase()}'),
      ], 0);
      
      // Add a blank row for spacing
      sheetObject.insertRowIterables([TextCellValue('')], 1);

      // Add headers at row 2
      List<String> headers = [
        'ID', 'Name', 'Type', 'Group', 'Mode', 'Manufacturer', 'Serial No',
        'Department', 'Status', 'Service Status', 'Warranty Upto',
        'Purchased Cost', 'Installation Date', 'Assigned Employee ID',
        'Has Warranty', 'College ID', 'Remarks', 'Need of Spares',
      ];
      sheetObject.insertRowIterables(headers.map((e) => TextCellValue(e)).toList(), 2);

      // Set column widths for Remarks and Need of Spares
      sheetObject.setColumnWidth(16, 40);
      sheetObject.setColumnWidth(17, 40);

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
          DoubleCellValue(equipment.purchasedCost), // Assuming purchasedCost is double
          TextCellValue(DateFormat('yyyy-MM-dd').format(equipment.installationDate)),
          TextCellValue(equipment.assignedEmployeeIds != null ? equipment.assignedEmployeeIds!.join(', ') : ''),
          BoolCellValue(equipment.hasWarranty), // Assuming hasWarranty is bool
          TextCellValue(equipment.collegeId),
          TextCellValue(''), // Remarks column
          TextCellValue(''), // Need of Spares column
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

      if (kIsWeb) {
        // For web, use the custom web download utility
        final fileName = 'equipments_${widget.collegeName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        downloadFileWeb(context, Uint8List.fromList(excelBytes), fileName);
      } else {
        // For non-web platforms (mobile/desktop)
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Equipments Excel File',
          fileName: 'equipments_${widget.collegeName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          final file = io.File(outputFile);
          await file.writeAsBytes(excelBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipments exported to $outputFile successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel export cancelled or failed.')),
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

  List<Equipment> _getFilteredEquipments(List<Equipment> equipments) {
    final query = _searchController.text.toLowerCase();
    
    // First filter by search query and department
    final filteredBySearchAndDept = equipments.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(query) ||
          e.id.toLowerCase().contains(query) ||
          e.department.toLowerCase().contains(query);
      
      final matchesDept = _selectedDepartmentFilter == null || 
          e.department == _selectedDepartmentFilter;
      
      return matchesQuery && matchesDept;
    }).toList();

    // Further filter by selected equipment name chip OR status chip
    return filteredBySearchAndDept.where((e) {
      bool matchesName = _selectedEquipmentNameFilter == null || e.name == _selectedEquipmentNameFilter;
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Working') {
        matchesStatus = e.isWorking;
      } else if (_selectedStatusFilter == 'Not Working') {
        matchesStatus = e.isNotWorking;
      }
      return matchesName && matchesStatus;
    }).toList();
  }

  Future<void> _toggleEquipmentStatus(Equipment equipment) async {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    final newStatus = equipment.status == 'Working' ? 'Not Working' : 'Working';
    final updatedEquipment = equipment.copyWith(status: newStatus);
    
    await equipmentProvider.updateEquipment(
      equipment.id, 
      updatedEquipment,
      notificationProvider: notificationProvider,
      updatedByRole: 'college',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${equipment.name} marked as $newStatus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final allEquipments = equipmentProvider.equipments;
    
    // Normalize collegeId comparison to handle whitespace
    final equipments = allEquipments
        .where((p) => p.collegeId.trim() == widget.collegeName.trim())
        .toList();
    
    // Debug logging
    print('🔍 [ManageEquipmentsScreen] College Name/ID: "${widget.collegeName}"');
    print('🔍 [ManageEquipmentsScreen] Total equipments in provider: ${allEquipments.length}');
    print('🔍 [ManageEquipmentsScreen] Filtered equipments for this college: ${equipments.length}');
    
    // Log all unique collegeIds to see what's in the database
    final allCollegeIds = allEquipments.map((e) => e.collegeId.trim()).toSet();
    print('🔍 [ManageEquipmentsScreen] All unique collegeIds in equipments: $allCollegeIds');
    
    // Log equipments that don't match
    final nonMatching = allEquipments.where((p) => p.collegeId.trim() != widget.collegeName.trim()).toList();
    if (nonMatching.isNotEmpty) {
      print('🔍 [ManageEquipmentsScreen] Found ${nonMatching.length} equipments with different collegeId:');
      for (var e in nonMatching.take(5)) {
        print('   - Equipment: ${e.name}, collegeId: "${e.collegeId}" (trimmed: "${e.collegeId.trim()}")');
      }
    }
    
    for (var p in equipments) {
      if (!_stickerKeys.containsKey(p.id)) {
        _stickerKeys[p.id] = GlobalKey();
      }
    }
    
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final departmentsList = departmentProvider.getDepartmentsForCollege(widget.collegeName);
    
    // Ensure unique department names for the filter dropdown
    final uniqueDeptNamesFilter = departmentsList.map((d) {
      return d.subSelectionType != null ? "${d.name} (${d.subSelectionType})" : d.name;
    }).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, ID or dept...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.blue),
                hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 15),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                if (uniqueDeptNamesFilter.isNotEmpty)
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDepartmentFilter,
                        hint: const Text('All Departments', style: TextStyle(fontSize: 13, color: Colors.blue)),
                        icon: const Icon(Icons.filter_list, size: 18, color: Colors.blue),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Departments', style: TextStyle(fontSize: 13)),
                          ),
                          ...uniqueDeptNamesFilter.map((name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name, style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDepartmentFilter = val;
                          });
                        },
                      ),
                    ),
                  ),
                const VerticalDivider(width: 20, indent: 12, endIndent: 12),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                  onPressed: _fetchEquipments,
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file, size: 20),
                  tooltip: 'Upload Excel',
                  onPressed: _uploadExcel,
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  tooltip: 'Export Excel',
                  onPressed: () => _exportEquipmentsToExcel(customList: _getFilteredEquipments(equipments)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  tooltip: 'Delete All',
                  onPressed: _deleteAllEquipments,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              final query = _searchController.text.toLowerCase();
              final filteredBySearchAndDept = equipments.where((e) {
                final matchesQuery = e.name.toLowerCase().contains(query) ||
                    e.id.toLowerCase().contains(query) ||
                    e.department.toLowerCase().contains(query);
                
                final matchesDept = _selectedDepartmentFilter == null || 
                    e.department == _selectedDepartmentFilter;
                
                return matchesQuery && matchesDept;
              }).toList();

              // Group by equipment name to count "same equipment"
              final Map<String, int> counts = {};
              int workingCount = 0;
              int notWorkingCount = 0;
              
              for (var e in filteredBySearchAndDept) {
                counts[e.name] = (counts[e.name] ?? 0) + 1;
                if (e.isWorking) {
                  workingCount++;
                } else {
                  notWorkingCount++;
                }
              }
              final sortedNames = counts.keys.toList()..sort();

              // Further filter by selected equipment name chip OR status chip
              final finalFilteredEquipments = _getFilteredEquipments(equipments);

              return Column(
                children: [
                  if (query.isNotEmpty || equipments.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sortedNames.isNotEmpty || workingCount > 0 || notWorkingCount > 0)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // "All" chip
                                  _buildFilterChip(
                                    label: 'All: ${filteredBySearchAndDept.length}',
                                    isSelected: _selectedEquipmentNameFilter == null && _selectedStatusFilter == null,
                                    onTap: () {
                                      setState(() {
                                        _selectedEquipmentNameFilter = null;
                                        _selectedStatusFilter = null;
                                      });
                                    },
                                    color: Colors.blue,
                                  ),
                                  // "Working" chip
                                  _buildFilterChip(
                                    label: 'Working: $workingCount',
                                    isSelected: _selectedStatusFilter == 'Working',
                                    onTap: () {
                                      setState(() {
                                        _selectedStatusFilter = _selectedStatusFilter == 'Working' ? null : 'Working';
                                        // Optional: clear name filter when status is selected? User didn't specify.
                                        // Keep both for compound filtering.
                                      });
                                    },
                                    color: Colors.green,
                                  ),
                                  // "Not Working" chip
                                  _buildFilterChip(
                                    label: 'Not Working: $notWorkingCount',
                                    isSelected: _selectedStatusFilter == 'Not Working',
                                    onTap: () {
                                      setState(() {
                                        _selectedStatusFilter = _selectedStatusFilter == 'Not Working' ? null : 'Not Working';
                                      });
                                    },
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8, child: VerticalDivider()),
                                  ...sortedNames.map((name) {
                                    final isSelected = _selectedEquipmentNameFilter == name;
                                    return _buildFilterChip(
                                      label: '$name: ${counts[name]}',
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedEquipmentNameFilter = null;
                                          } else {
                                            _selectedEquipmentNameFilter = name;
                                          }
                                        });
                                      },
                                      color: Colors.blue,
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ManagementListWidget(
                      items: finalFilteredEquipments.map((e) => ManagementListItem(
                        id: e.id,
                        title: e.name,
                        subtitle: e.department,
                        icon: Icons.devices_other,
                        iconColor: const Color(0xFF2563EB),
                        badge: e.status,
                        badgeColor: e.status == 'Working' ? Colors.green : (e.status == 'Under Maintenance' ? Colors.orange : Colors.red),
                        actions: [
                          ManagementAction(
                            label: 'View',
                            icon: Icons.remove_red_eye,
                            color: const Color(0xFF2563EB),
                            onPressed: () => _showEquipmentDetails(e),
                          ),
                          ManagementAction(
                            label: 'Toggle',
                            icon: e.status == 'Working' ? Icons.check_circle : Icons.error_outline,
                            color: e.status == 'Working' ? Colors.green : Colors.red,
                            onPressed: () => _toggleEquipmentStatus(e),
                          ),
                          ManagementAction(
                            label: 'Download',
                            icon: Icons.download,
                            color: const Color(0xFF059669),
                            onPressed: () => _exportStickerAsPng(e),
                          ),
                          ManagementAction(
                            label: 'Edit',
                            icon: Icons.edit,
                            color: const Color(0xFF16A34A),
                            onPressed: () async => await _editEquipment(e),
                          ),
                          ManagementAction(
                            label: 'Delete',
                            icon: Icons.delete,
                            color: const Color(0xFFDC2626),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Equipment'),
                                  content: const Text('Are you sure you want to delete this equipment?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deleteEquipment(e.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Equipment deleted.')),
                                );
                              }
                            },
                          ),
                        ],
                      )).toList(),
                      emptyMessage: query.isEmpty ? 'No equipments found. Add one to get started!' : 'No equipments match your search.',
                    ),
                  ),
                ],
              );
            },
          ),
          ...equipments.map((p) {
            // Ensure the key exists
            if (!_stickerKeys.containsKey(p.id)) {
              debugPrint('🔑 [STICKER] Creating new GlobalKey for equipment: ${p.id}');
              _stickerKeys[p.id] = GlobalKey();
            }
            debugPrint('📌 [STICKER] Using key for equipment: ${p.id}');
            return Positioned(
              top: -9999,
              left: -9999,
              child: RepaintBoundary(
                key: _stickerKeys[p.id],
                child: _buildStickerWidget(p),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEquipmentDialog,
        tooltip: 'Add Equipment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEquipmentDetails(Equipment p) {
    showDialog(
      context: context,
      builder: (ctx) => ModernDetailsDialog(
        title: p.name,
        details: [
          DetailRow(label: 'ID', value: p.id),
          DetailRow(label: 'Type', value: p.type),
          DetailRow(label: 'Group', value: p.group),
          DetailRow(label: 'Mode', value: p.mode),
          DetailRow(label: 'Manufacturer', value: p.manufacturer),
          DetailRow(label: 'Serial Number', value: p.serialNo),
          DetailRow(label: 'Department', value: p.department),
          DetailRow(label: 'Status', value: p.status),
          DetailRow(label: 'Service Status', value: p.service),
          DetailRow(
            label: 'Warranty Upto',
            value: p.warrantyUpto != null ? DateFormat('yyyy-MM-dd').format(p.warrantyUpto!) : '-',
          ),
          DetailRow(label: 'Purchased Cost', value: '₹${p.purchasedCost.toString()}'),
          DetailRow(
            label: 'Installation Date',
            value: DateFormat('yyyy-MM-dd').format(p.installationDate),
          ),
          DetailRow(label: 'Employee Assigned', value: p.assignedEmployeeIds != null ? p.assignedEmployeeIds!.join(', ') : '-'),
          DetailRow(label: 'College', value: p.collegeId),
        ],
        qrCodeWidget: QrImageView(
          data: p.id,
          version: QrVersions.auto,
          size: 150,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildStickerWidget(Equipment p) {
    const double stickerW = 350; // 7 cm at ~50 px/cm
    const double stickerH = 200; // 4 cm at ~50 px/cm
    const Color navyBlue  = Color(0xFF0A1628);
    const Color tealBlue  = Color(0xFF00B4D8);
    const Color goldColor = Color(0xFFFFD60A);

    final qrData = 'https://qrmed-supreme.netlify.app/?id=${p.id}';

    return Container(
      width: stickerW,
      height: stickerH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navyBlue, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ══ HEADER – navy band ══════════════════════════════════
          Container(
            color: navyBlue,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Supreme Logo
                if (_supremeLogoBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.memory(
                        _supremeLogoBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        isAntiAlias: true,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.asset(
                        'assets/supreme_logo_transparent.png',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),

                // Brand name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'SUPREME',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'BIOMEDICAL',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: tealBlue,
                        letterSpacing: 2,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Logo
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _logoBytes != null
                      ? Image.memory(
                          _logoBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          isAntiAlias: true,
                        )
                      : Image.asset(
                          'assets/favicon.png',
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                ),
              ],
            ),
          ),

          // ══ TEAL / GOLD GRADIENT STRIP ══════════════════════════
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [tealBlue, goldColor, tealBlue],
              ),
            ),
          ),

          // ══ BODY – left info | right QR ═════════════════════════
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── LEFT: College ID + Asset ID ─────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // College ID label
                        const Text(
                          'COLLEGE ID',
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_college != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _college!.id,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: navyBlue,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                          ),

                        const SizedBox(height: 6),

                        // Thin teal divider
                        Container(
                          height: 1.5,
                          width: 60,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tealBlue, Colors.transparent],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Asset ID label
                        const Text(
                          'ASSET ID',
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            p.id,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Vertical divider ────────────────────────────
                Container(width: 1, color: Colors.black12),

                // ── RIGHT: QR Code fills the panel ──────────────
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 110,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: navyBlue,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: navyBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ══ THIN RULE ═══════════════════════════════════════════
          Container(height: 1, color: Colors.black12),

          // ══ SCAN FOOTER ══════════════════════════════════════════
          Container(
            color: const Color(0xFFF0F8FF),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, color: tealBlue, size: 12),
                const SizedBox(width: 5),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 7.5, color: Colors.black87),
                    children: [
                      TextSpan(text: 'Scan with '),
                      TextSpan(
                        text: 'QR Med App',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: tealBlue,
                        ),
                      ),
                      TextSpan(text: ' from '),
                      TextSpan(
                        text: 'Google Play Store',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34A853),
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ',
                        style: TextStyle(color: Colors.black38),
                      ),
                      TextSpan(
                        text: 'qrmed-supreme.netlify.app',
                        style: TextStyle(
                          color: Color(0xFF0066CC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ══ BOTTOM NAVY ACCENT STRIP ════════════════════════════
          Container(height: 4, color: navyBlue),
        ],
      ),
    );
  }
}
