import 'package:flutter/material.dart';

class ModernDetailsDialog extends StatelessWidget {
  final String title;
  final List<DetailRow> details;
  final Widget? qrCodeWidget;
  final List<ActionButton>? actionButtons;

  const ModernDetailsDialog({
    super.key,
    required this.title,
    required this.details,
    this.qrCodeWidget,
    this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 32), // Spacer
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // If the first detail is "Status", show it as a badge
                    _buildTopBadge(),
                  ],
                ),
              ),

              // Content Section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      // Grid of details
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: details.map((detail) => _buildModernItem(context, detail)).toList(),
                      ),
                      
                      if (qrCodeWidget != null) ...[
                        const SizedBox(height: 30),
                        const Divider(),
                        const SizedBox(height: 20),
                        const Text(
                          'ASSET IDENTIFIER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: qrCodeWidget,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              if (actionButtons != null && actionButtons!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: actionButtons!.map((action) => _buildActionButton(action)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBadge() {
    // Try to find a "Status" or "Role" to show at the top
    String? statusValue;
    try {
      final statusDetail = details.firstWhere(
        (d) => d.label.toLowerCase() == 'status' || d.label.toLowerCase() == 'role'
      );
      statusValue = statusDetail.value;
    } catch (_) {}

    if (statusValue == null) return const SizedBox.shrink();

    Color badgeColor = Colors.white.withOpacity(0.2);
    Color textColor = Colors.white;
    
    if (statusValue.toLowerCase() == 'working' || statusValue.toLowerCase() == 'active') {
      badgeColor = Colors.green.shade400.withOpacity(0.4);
      textColor = Colors.greenAccent.shade100;
    } else if (statusValue.toLowerCase() == 'not working' || statusValue.toLowerCase() == 'inactive') {
      badgeColor = Colors.red.shade400.withOpacity(0.4);
      textColor = Colors.redAccent.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Text(
        statusValue.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernItem(BuildContext context, DetailRow detail) {
    // Determine width based on text length
    bool isLong = detail.value.length > 20 || detail.label.toLowerCase() == 'name' || detail.label.toLowerCase() == 'college';
    double width = isLong ? (MediaQuery.of(context).size.width - 80) : 150;
    if (width > 220 && !isLong) width = 220;

    // Special coloring for Status values in the card
    Color valueColor = Color(0xFF1E293B);
    if (detail.label.toLowerCase() == 'status') {
      if (detail.value.toLowerCase() == 'working' || detail.value.toLowerCase() == 'active') {
        valueColor = Colors.green.shade700;
      } else if (detail.value.toLowerCase() == 'not working' || detail.value.toLowerCase() == 'inactive') {
        valueColor = Colors.red.shade700;
      }
    }

    return Container(
      width: isLong ? double.infinity : null,
      constraints: BoxConstraints(minWidth: isLong ? 0 : 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_getIconForLabel(detail.label), size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                detail.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail.value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ActionButton action) {
    return ElevatedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: action.color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('id')) return Icons.tag;
    if (l.contains('name')) return Icons.badge_outlined;
    if (l.contains('status')) return Icons.info_outline;
    if (l.contains('dept') || l.contains('department')) return Icons.business_outlined;
    if (l.contains('group')) return Icons.folder_outlined;
    if (l.contains('manufacturer') || l.contains('mfg')) return Icons.factory_outlined;
    if (l.contains('type')) return Icons.category_outlined;
    if (l.contains('mode')) return Icons.settings_input_component;
    if (l.contains('serial')) return Icons.numbers;
    if (l.contains('cost') || l.contains('value')) return Icons.payments_outlined;
    if (l.contains('date')) return Icons.calendar_today_outlined;
    if (l.contains('assigned') || l.contains('employee')) return Icons.person_outline;
    if (l.contains('college')) return Icons.school_outlined;
    if (l.contains('phone')) return Icons.phone_outlined;
    if (l.contains('email')) return Icons.email_outlined;
    if (l.contains('role')) return Icons.work_outline;
    if (l.contains('warranty')) return Icons.verified_user_outlined;
    return Icons.circle_outlined;
  }
}

class DetailRow {
  final String label;
  final String value;

  DetailRow({required this.label, required this.value});
}

class ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFF2563EB),
  });
}
