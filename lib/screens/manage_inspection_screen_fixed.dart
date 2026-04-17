import 'package:supreme_institution/models/department.dart';
import 'package:supreme_institution/providers/department_provider.dart';
import 'package:supreme_institution/screens/manage_requirements_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/models/college.dart';
import 'package:supreme_institution/models/inspection_result.dart';
import 'package:supreme_institution/providers/college_provider.dart';
import 'package:supreme_institution/providers/inspection_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageInspectionScreen extends StatefulWidget {
  const ManageInspectionScreen({super.key});

  @override
  _ManageInspectionScreenState createState() => _ManageInspectionScreenState();
}

class _ManageInspectionScreenState extends State<ManageInspectionScreen> {
  College? _selectedCollege;
  Department? _selectedDepartment;
  InspectionResult? _inspectionResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
    });
  }

  Future<void> _runInspection() async {
    if (_selectedCollege == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final inspectionProvider = Provider.of<InspectionProvider>(context, listen: false);
    final result = await inspectionProvider.performInspectionForCollege(
      college: _selectedCollege!,
      department: _selectedDepartment,
    );

    setState(() {
      _inspectionResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final collegeProvider = Provider.of<CollegeProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inspection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<College>(
              isExpanded: true,
              initialValue: _selectedCollege,
              decoration: const InputDecoration(labelText: 'Select College'),
              selectedItemBuilder: (BuildContext context) {
                return collegeProvider.colleges.map((college) {
                  return Text(
                    college.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                }).toList();
              },
              items: collegeProvider.colleges.map((college) {
                return DropdownMenuItem<College>(
                  value: college,
                  child: Text(
                    college.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (college) {
                setState(() {
                  _selectedCollege = college;
                  _selectedDepartment = null;
                  _inspectionResult = null;
                });
              },
            ),
            const SizedBox(height: 16),
              DropdownButtonFormField<Department>(
                isExpanded: true,
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(labelText: 'Select Department'),
                selectedItemBuilder: (BuildContext context) {
                  return departmentProvider.getDepartmentsForCollege(_selectedCollege!.id).map((department) {
                    final displayName = department.subSelectionType != null 
                        ? "${department.name} (${department.subSelectionType})"
                        : department.name;
                    return Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: departmentProvider.getDepartmentsForCollege(_selectedCollege!.id).map((department) {
                  final displayName = department.subSelectionType != null 
                      ? "${department.name} (${department.subSelectionType})"
                      : department.name;
                  return DropdownMenuItem<Department>(
                    value: department,
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (department) {
                  setState(() {
                    _selectedDepartment = department;
                    _inspectionResult = null;
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectedCollege != null && !_isLoading ? _runInspection : null,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Perform Inspection'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageRequirementsScreen(),
                      ),
                    );
                  },
                  child: const Text('Manage Requirements'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReferenceLink(
              'Check DCI Inspection Proformas',
              'https://dciindia.gov.in/InspetionProfomas.aspx',
            ),
            const SizedBox(height: 24),
            if (_inspectionResult != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspection Results for ${_selectedCollege!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Overall Status: ${_inspectionResult!.passed ? 'PASS' : 'FAIL'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _inspectionResult!.passed ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Missing Equipment',
                        items: _inspectionResult!.missingEquipment,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Missing Staff',
                        items: _inspectionResult!.missingStaff,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Excess Equipment',
                        items: _inspectionResult!.excessEquipment,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Excess Staff',
                        items: _inspectionResult!.excessStaff,
                      ),
                      const SizedBox(height: 16),
                      _buildItemList(
                        title: 'Notes',
                        items: _inspectionResult!.notes,
                      ),
                      const SizedBox(height: 24),
                      _buildReferenceSection(_selectedCollege!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList({required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('None')
        else
          ...items.map((item) => Text('• $item')),
      ],
    );
  }

  Widget _buildReferenceSection(College college) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reference Standards',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (college.type.toUpperCase().contains('MBBS'))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReferenceLink(
                'MBBS - 100 Admissions',
                'https://www.nmc.org.in/wp-content/uploads/2017/10/Minimum-Standard-Requirements-for-100-Admissions-1.pdf',
              ),
              const SizedBox(height: 8),
              _buildReferenceLink(
                'MBBS - 200 Admissions',
                'https://www.nmc.org.in/wp-content/uploads/2017/10/STANDARD-FOR-200.pdf',
              ),
            ],
          ),
        if (college.type.toUpperCase().contains('BDS') || college.type.toUpperCase().contains('MDS'))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildReferenceLink(
              'BDS / MDS Standards',
              'https://dciindia.gov.in/InspetionProfomas.aspx',
            ),
          ),
        if (college.type.toUpperCase().contains('HOSPITAL'))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildReferenceLink(
                'National Level Hospital Standards',
                'https://clinicalestablishments.mohfw.gov.in/sites/default/files/2022-06/147.pdf',
              ),
              const SizedBox(height: 8),
              _buildReferenceLink(
                'State Level Hospital Standards (AP)',
                'https://www.scribd.com/document/746442335/Andhra-Pradesh-Allopathic-Private-Medical-Care-Establishments-act',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReferenceLink(String title, String url) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
