import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supreme_institution/screens/add_edit_college_screen.dart';
import '../models/college.dart';
import '../providers/college_provider.dart';
import '../widgets/management_list_widget.dart';

class ManageCollegesScreen extends StatefulWidget {
  const ManageCollegesScreen({super.key});

  @override
  State<ManageCollegesScreen> createState() => _ManageCollegesScreenState();
}

class _ManageCollegesScreenState extends State<ManageCollegesScreen> {
  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    await Provider.of<CollegeProvider>(context, listen: false).fetchColleges();
    setState(() {});
  }

  Future<void> _handleDeleteCollege(College c) async {
    print('🔴🔴🔴 [_handleDeleteCollege] Starting delete process for: ${c.id} - ${c.name}');
    debugPrint('🔴🔴🔴 [_handleDeleteCollege] Starting delete process for: ${c.id} - ${c.name}');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        print('🔴🔴🔴 [DIALOG] Showing delete confirmation dialog');
        return AlertDialog(
          title: const Text('Delete College'),
          content: const Text(
              'Are you sure you want to delete this college?\n\n'
              'This will also delete all related data:\n'
              '• All equipments\n'
              '• All employees\n'
              '• All departments\n'
              '• All tickets\n\n'
              'This action cannot be undone!'),
          actions: [
            TextButton(
              onPressed: () {
                print('🔴🔴🔴 [DIALOG] Cancel button clicked');
                Navigator.of(ctx).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print('🔴🔴🔴 [DIALOG] Delete button clicked in dialog');
                Navigator.of(ctx).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    print('🔴🔴🔴 [DIALOG RESULT] Confirm result: $confirm');
    debugPrint('🔴🔴🔴 [DIALOG RESULT] Confirm result: $confirm');
    
    if (confirm == true) {
      print('🔴🔴🔴 [CONFIRMED] User confirmed deletion, proceeding...');
      debugPrint('🔴🔴🔴 [CONFIRMED] User confirmed deletion, proceeding...');
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        print('🔴🔴🔴 [DELETE START] Attempting to delete college: ${c.id} (${c.name})');
        debugPrint('🔴🔴🔴 [DELETE START] Attempting to delete college: ${c.id} (${c.name})');
        
        await Provider.of<CollegeProvider>(context, listen: false)
            .deleteCollege(c.id);
        
        print('🔴🔴🔴 [DELETE SUCCESS] College deleted, refreshing list...');
        debugPrint('🔴🔴🔴 [DELETE SUCCESS] College deleted, refreshing list...');
        await _fetchColleges();

        // Close loading indicator
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('College and all related data deleted successfully.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e, stackTrace) {
        print('🔴🔴🔴 [DELETE ERROR] Error deleting college: $e');
        print('🔴🔴🔴 [DELETE ERROR] Stack trace: $stackTrace');
        debugPrint('🔴🔴🔴 [DELETE ERROR] Error deleting college: $e');
        debugPrint('🔴🔴🔴 [DELETE ERROR] Stack trace: $stackTrace');
        
        // Close loading indicator
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting college: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } else {
      print('🔴🔴🔴 [CANCELLED] User cancelled deletion');
      debugPrint('🔴🔴🔴 [CANCELLED] User cancelled deletion');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colleges = Provider.of<CollegeProvider>(context).colleges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Colleges'),
        elevation: 0,
      ),
      body: ManagementListWidget(
        items: colleges
            .map(
              (c) => ManagementListItem(
                id: c.id,
                title: c.name,
                subtitle: '${c.city} • ${c.type} • Code: ${c.collegeCode}',
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF8B5CF6),
                actions: [
                  ManagementAction(
                    label: 'View',
                    icon: Icons.remove_red_eye,
                    color: const Color(0xFF2563EB),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('College Details'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow('Name', c.name),
                                _DetailRow('Code', c.collegeCode),
                                _DetailRow('ID', c.id),
                                _DetailRow('City', c.city),
                                _DetailRow('Type', c.type),
                                _DetailRow('Seats', c.seats),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ManagementAction(
                    label: 'Edit',
                    icon: Icons.edit,
                    color: const Color(0xFF16A34A),
                    onPressed: () async {
                      final updatedCollege =
                          await Navigator.of(context).push<College>(
                        MaterialPageRoute(
                          builder: (context) => AddEditCollegeScreen(
                            college: c,
                          ),
                        ),
                      );
                      if (updatedCollege != null) {
                        await Provider.of<CollegeProvider>(context,
                                listen: false)
                            .updateCollege(updatedCollege.id, updatedCollege);
                        await _fetchColleges();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('College updated successfully.')),
                        );
                      }
                    },
                  ),
                  ManagementAction(
                    label: 'Delete',
                    icon: Icons.delete,
                    color: const Color(0xFFDC2626),
                    onPressed: () {
                      print('🔴🔴🔴 [DELETE BUTTON CLICKED] Delete button pressed for college: ${c.id} - ${c.name}');
                      debugPrint('🔴🔴🔴 [DELETE BUTTON CLICKED] Delete button pressed for college: ${c.id} - ${c.name}');
                      _handleDeleteCollege(c);
                    },
                  ),
                ],
              ),
            )
            .toList(),
        emptyMessage: 'No colleges found',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newCollege = await Navigator.of(context).push<College>(
            MaterialPageRoute(
              builder: (context) => const AddEditCollegeScreen(),
            ),
          );
          if (newCollege != null) {
            await Provider.of<CollegeProvider>(context, listen: false)
                .addCollege(newCollege);
            await _fetchColleges();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('College added successfully.')),
            );
          }
        },
        tooltip: 'Add College',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}