import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';

import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/modern_details_dialog.dart';

class ManageProductsScreen extends StatefulWidget {
  final String collegeName;
  const ManageProductsScreen({super.key, required this.collegeName});

  @override
  _ManageProductsScreenState createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  // Controllers
  final _equipmentNameController = TextEditingController();
  final _equipmentTypeController = TextEditingController();
  final _equipmentGroupController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialNoController = TextEditingController();
  final _departmentController = TextEditingController();
  final _statusController = TextEditingController();
  final _serviceStatusController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _purchasedValueController = TextEditingController();
  final _employeeAssignedController = TextEditingController();
  final _verifiedByController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  DateTime? _purchasedDate;
  DateTime? _verifiedDate;
  String _generatedId = '';
  final Map<String, GlobalKey> _stickerKeys = {};

  Future<void> _exportStickerAsPng(Product product) async {
    try {
      // Wait for the next frame to ensure the widget is built
      await Future.delayed(const Duration(milliseconds: 100));
      
      final key = _stickerKeys[product.id];
      if (key == null || key.currentContext == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Sticker not ready. Please try again.')),
        );
        return;
      }

      RenderRepaintBoundary? boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not find sticker boundary.')),
        );
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final result = await ImageGallerySaver.saveImage(
          byteData.buffer.asUint8List(),
          name: 'product_${product.id}_sticker',
          quality: 100,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['isSuccess'] == true 
                ? 'Sticker exported to gallery successfully!' 
                : 'Failed to export sticker.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting sticker: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  Future<void> _fetchProducts() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    setState(() {});
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _equipmentTypeController.dispose();
    _equipmentGroupController.dispose();
    _deviceTypeController.dispose();
    _manufacturerController.dispose();
    _serialNoController.dispose();
    _departmentController.dispose();
    _statusController.dispose();
    _serviceStatusController.dispose();
    _warrantyController.dispose();
    _purchasedValueController.dispose();
    _employeeAssignedController.dispose();
    _verifiedByController.dispose();
    super.dispose();
  }

  void _fillFormWithProduct(Product product) {
    _equipmentNameController.text = product.equipmentName;
    _equipmentTypeController.text = product.equipmentType;
    _equipmentGroupController.text = product.equipmentGroup;
    _deviceTypeController.text = product.deviceType;
    _manufacturerController.text = product.manufacturer;
    _serialNoController.text = product.serialNo;
    _departmentController.text = product.department;
    _statusController.text = product.status;
    _serviceStatusController.text = product.serviceStatus;
    _warrantyController.text = product.warranty != null ? DateFormat('yyyy-MM-dd').format(product.warranty!) : '';
    _purchasedValueController.text = product.purchasedValue?.toString() ?? '';
    _purchasedDate = product.purchasedDate;
    _employeeAssignedController.text = product.employeeAssigned ?? '';
    _verifiedDate = product.verifiedDate;
    _verifiedByController.text = product.verifiedBy ?? '';
    _generatedId = product.id;
  }

  void _clearForm() {
    _equipmentNameController.clear();
    _equipmentTypeController.clear();
    _equipmentGroupController.clear();
    _deviceTypeController.clear();
    _manufacturerController.clear();
    _serialNoController.clear();
    _departmentController.clear();
    _statusController.clear();
    _serviceStatusController.clear();
    _warrantyController.clear();
    _purchasedValueController.clear();
    _employeeAssignedController.clear();
    _verifiedByController.clear();
    _purchasedDate = null;
    _verifiedDate = null;
    _generatedId = '';
  }

  Future<void> _showAddProductDialog() async {
    _clearForm();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: _buildProductForm(),
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
              final newProduct = Product(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                equipmentName: _equipmentNameController.text.trim(),
                equipmentType: _equipmentTypeController.text.trim(),
                equipmentGroup: _equipmentGroupController.text.trim(),
                deviceType: _deviceTypeController.text.trim(),
                manufacturer: _manufacturerController.text.trim(),
                serialNo: _serialNoController.text.trim(),
                department: _departmentController.text.trim(),
                status: _statusController.text.trim(),
                serviceStatus: _serviceStatusController.text.trim(),
                warranty: _warrantyController.text.isNotEmpty ? DateTime.tryParse(_warrantyController.text) : null,
                purchasedValue: double.tryParse(_purchasedValueController.text),
                purchasedDate: _purchasedDate,
                employeeAssigned: _employeeAssignedController.text.trim(),
                verifiedDate: _verifiedDate,
                verifiedBy: _verifiedByController.text.trim(),
                collegeId: widget.collegeName,
              );
              await Provider.of<ProductProvider>(context, listen: false).addProduct(newProduct);
              setState(() {});
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product added successfully.')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProduct(Product oldProduct) async {
    _fillFormWithProduct(oldProduct);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Product'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: _buildProductForm(),
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
              final updatedProduct = Product(
                id: oldProduct.id,
                equipmentName: _equipmentNameController.text.trim(),
                equipmentType: _equipmentTypeController.text.trim(),
                equipmentGroup: _equipmentGroupController.text.trim(),
                deviceType: _deviceTypeController.text.trim(),
                manufacturer: _manufacturerController.text.trim(),
                serialNo: _serialNoController.text.trim(),
                department: _departmentController.text.trim(),
                status: _statusController.text.trim(),
                serviceStatus: _serviceStatusController.text.trim(),
                warranty: _warrantyController.text.isNotEmpty ? DateTime.tryParse(_warrantyController.text) : null,
                purchasedValue: double.tryParse(_purchasedValueController.text),
                purchasedDate: _purchasedDate,
                employeeAssigned: _employeeAssignedController.text.trim(),
                verifiedDate: _verifiedDate,
                verifiedBy: _verifiedByController.text.trim(),
                collegeId: widget.collegeName,
              );
              await Provider.of<ProductProvider>(context, listen: false).updateProduct(oldProduct.id, updatedProduct);
              setState(() {});
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product updated successfully.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    await Provider.of<ProductProvider>(context, listen: false).deleteProduct(id);
    setState(() {});
  }

  Widget _buildProductForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _equipmentNameController,
            decoration: const InputDecoration(labelText: 'Equipment Name'),
            validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
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
            decoration: const InputDecoration(labelText: 'Mode'),
          ),
          TextFormField(
            controller: _manufacturerController,
            decoration: const InputDecoration(labelText: 'Manufacturer'),
          ),
          TextFormField(
            controller: _serialNoController,
            decoration: const InputDecoration(labelText: 'Serial No'),
          ),
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(labelText: 'Department'),
          ),
          TextFormField(
            controller: _statusController,
            decoration: const InputDecoration(labelText: 'Status'),
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
              if (date != null) setState(() => _purchasedDate = date);
            },
          ),
          TextFormField(
            controller: _employeeAssignedController,
            decoration: const InputDecoration(labelText: 'Employee Assigned'),
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
              if (date != null) setState(() => _verifiedDate = date);
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

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products
        .where((p) => p.collegeId == widget.collegeName).toList();
    
    // Ensure all products have keys
    for (var p in products) {
      if (!_stickerKeys.containsKey(p.id)) {
        _stickerKeys[p.id] = GlobalKey();
      }
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: Stack(
        children: [
          products.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, idx) {
                    final p = products[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(p.equipmentName),
                        subtitle: Text('ID: ${p.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download),
                              tooltip: 'Export Sticker',
                              onPressed: () => _exportStickerAsPng(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              tooltip: 'View',
                              onPressed: () => _showProductDetails(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () async {
                                await _editProduct(p);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: const Text('Are you sure you want to delete this product?'),
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
                                  await _deleteProduct(p.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Product deleted.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          // Offstage sticker widgets for export
          ...products.map((p) => Offstage(
                offstage: true,
                child: RepaintBoundary(
                  key: _stickerKeys[p.id],
                  child: _buildStickerWidget(p),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProductDetails(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => ModernDetailsDialog(
        title: 'Product Details',
        details: [
          DetailRow(label: 'ID', value: p.id),
          DetailRow(label: 'Name', value: p.equipmentName),
          DetailRow(label: 'Type', value: p.equipmentType),
          DetailRow(label: 'Group', value: p.equipmentGroup),
          DetailRow(label: 'Mode', value: p.deviceType),
          DetailRow(label: 'Manufacturer', value: p.manufacturer),
          DetailRow(label: 'Serial', value: p.serialNo),
          DetailRow(label: 'Department', value: p.department),
          DetailRow(label: 'Status', value: p.status),
          DetailRow(label: 'Service Status', value: p.serviceStatus),
          DetailRow(
            label: 'Warranty',
            value: p.warranty != null ? DateFormat('yyyy-MM-dd').format(p.warranty!) : '-',
          ),
          DetailRow(label: 'Purchased Value', value: p.purchasedValue?.toString() ?? '-'),
          DetailRow(
            label: 'Purchased Date',
            value: p.purchasedDate != null ? DateFormat('yyyy-MM-dd').format(p.purchasedDate!) : '-',
          ),
          DetailRow(label: 'Employee Assigned', value: p.employeeAssigned ?? '-'),
          DetailRow(
            label: 'Verified Date',
            value: p.verifiedDate != null ? DateFormat('yyyy-MM-dd').format(p.verifiedDate!) : '-',
          ),
          DetailRow(label: 'Verified By', value: p.verifiedBy ?? '-'),
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

  Widget _buildStickerWidget(Product p) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            'ID: ${p.id}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: QrImageView(
              data: p.id,
              version: QrVersions.auto,
              size: 120,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan QR code for details',
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const Text(
            'Download our app!',
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}