import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added for image picking
import 'package:firebase_storage/firebase_storage.dart'; // Added for Firebase Storage
import 'package:provider/provider.dart';
import 'dart:io'; // For File

import '../models/college.dart';
import '../providers/requirements_provider.dart';

class AddEditCollegeScreen extends StatefulWidget {
  final College? college;
  const AddEditCollegeScreen({super.key, this.college});

  @override
  State<AddEditCollegeScreen> createState() => _AddEditCollegeScreenState();
}

class _AddEditCollegeScreenState extends State<AddEditCollegeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _type;
  String? _seats;
  bool _obscurePassword = true;
  final TextEditingController _cityController = TextEditingController();

  File? _pickedImage; // New: to store the picked image file
  String? _logoUrl; // New: to store the URL of the uploaded logo

  @override
  void initState() {
    super.initState();
    if (widget.college != null) {
      _nameController.text = widget.college!.name;
      _codeController.text = widget.college!.collegeCode;
      
      // Normalize type to match requirements keys (BDS or MBBS)
      String type = widget.college!.type;
      if (type.toUpperCase() == 'DENTAL' || type.toUpperCase() == 'BDS') {
        _type = 'BDS';
      } else if (type.toUpperCase() == 'MEDICAL' || type.toUpperCase() == 'MBBS') {
        _type = 'MBBS';
      } else {
        _type = type;
      }
      
      _seats = widget.college!.seats;
      _passwordController.text = widget.college!.password;
      _cityController.text = widget.college!.city;
      _logoUrl = widget.college!.logoUrl; // New: Initialize logoUrl if college has one
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _generatedId {
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '');
    final city = _cityController.text.trim().toLowerCase().replaceAll(' ', '');
    final type = _type?.toLowerCase() ?? '';
    if (name.isNotEmpty && city.isNotEmpty && type.isNotEmpty) {
      return '$name-$type@$city.in';
    }
    return '';
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // New: Function to pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Image quality reduced

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // New: Function to upload image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_pickedImage == null) {
      return _logoUrl; // If no new image picked, return existing URL
    }

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('college_logos')
          .child('${_generatedId}_${DateTime.now().toIso8601String()}.jpg'); // Unique name

      await ref.putFile(_pickedImage!);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _saveCollege() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _seats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select type and seats')),
      );
      return;
    }

    String? finalLogoUrl = _logoUrl; // Start with existing logo URL
    if (_pickedImage != null) { // If a new image is picked
      finalLogoUrl = await _uploadImage(); // Upload and get new URL
      if (finalLogoUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload logo.')),
          );
        }
        return;
      }
    }

    final college = College(
      id: _generatedId,
      collegeCode: _codeController.text.trim(),
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      type: _type!,
      seats: _seats!,
      password: _passwordController.text.trim(),
      logoUrl: finalLogoUrl, // New: Pass the logo URL
    );
    Navigator.of(context).pop(college);
  }

  @override
  Widget build(BuildContext context) {
    final requirementsProvider = Provider.of<RequirementsProvider>(context);
    final availableCourses = requirementsProvider.requirements.keys.toList()..sort();
    
    // Initialize default type if not set
    if (_type == null && availableCourses.isNotEmpty) {
      // Try to find BDS or MBBS as defaults, otherwise first available
      if (availableCourses.contains('BDS')) {
        _type = 'BDS';
      } else if (availableCourses.contains('MBBS')) {
        _type = 'MBBS';
      } else {
        _type = availableCourses.first;
      }
    }

    // Get available capacities for selected course
    final List<String> availableSeats = _type != null 
        ? (requirementsProvider.requirements[_type!]?.keys.toList() ?? [])
        : [];
    
    // Sort seats numerically
    if (availableSeats.isNotEmpty) {
      availableSeats.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }

    // Initialize default seats if not set or invalid
    if (_type != null && (_seats == null || !availableSeats.contains(_seats))) {
      if (availableSeats.isNotEmpty) {
        _seats = availableSeats.first;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.college == null ? 'Add College' : 'Edit College')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New: Logo Upload Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (_logoUrl != null ? NetworkImage(_logoUrl!) : null),
                      child: _pickedImage == null && _logoUrl == null
                          ? Icon(Icons.school, size: 60, color: Colors.grey.shade600)
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_pickedImage != null || _logoUrl != null ? 'Change Logo' : 'Add Logo'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'College Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter college name' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Code (3 digits)'),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length != 3) return 'Must be 3 digits';
                        if (int.tryParse(v) == null) return 'Must be numeric';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => v == null || v.isEmpty ? 'Enter city' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _type,
                      selectedItemBuilder: (BuildContext context) {
                        return availableCourses.map((String type) {
                          return Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }).toList();
                      },
                      items: availableCourses.map((course) => DropdownMenuItem(
                        value: course,
                        child: Text(course, overflow: TextOverflow.ellipsis, maxLines: 1),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _type = val!;
                          // Re-evaluate seats for this course
                          final newCapacities = requirementsProvider.requirements[_type!]?.keys.toList() ?? [];
                          if (newCapacities.isNotEmpty) {
                            _seats = newCapacities.first;
                          } else {
                            _seats = null;
                          }
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _seats,
                      selectedItemBuilder: (BuildContext context) {
                        return availableSeats.map((String seat) {
                          return Text(
                            seat,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }).toList();
                      },
                      items: availableSeats.map((seat) => DropdownMenuItem(
                        value: seat,
                        child: Text(seat, overflow: TextOverflow.ellipsis, maxLines: 1),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _seats = val!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Seats'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (v.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Auto-generated ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: Text(_generatedId.isEmpty ? 'Will be generated based on name and city' : _generatedId,
                  style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCollege,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.college == null ? 'Add College' : 'Update College',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}