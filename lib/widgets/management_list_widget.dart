import 'package:flutter/material.dart';

class ManagementListItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final List<ManagementAction> actions;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  ManagementListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.actions = const [],
    this.badge,
    this.badgeColor,
    this.onTap,
  });
}

class ManagementAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  ManagementAction({
    required this.label,
    required this.icon,
    this.color = const Color(0xFF2563EB),
    required this.onPressed,
  });
}

class ManagementListWidget extends StatelessWidget {
  final List<ManagementListItem> items;
  final String emptyMessage;
  final bool isLoading;
  final ScrollPhysics? scrollPhysics;

  const ManagementListWidget({
    super.key,
    required this.items,
    this.emptyMessage = 'No items found',
    this.isLoading = false,
    this.scrollPhysics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: scrollPhysics ?? const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ManagementListItemWidget(item: item);
      },
    );
  }
}

class _ManagementListItemWidget extends StatefulWidget {
  final ManagementListItem item;

  const _ManagementListItemWidget({required this.item});

  @override
  State<_ManagementListItemWidget> createState() =>
      _ManagementListItemWidgetState();
}

class _ManagementListItemWidgetState extends State<_ManagementListItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return GestureDetector(
      onTap: widget.item.onTap ?? _toggleExpand,
      child: AnimatedBuilder(
        animation: _expandController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Main Item Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (widget.item.iconColor ?? const Color(0xFF2563EB))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.item.icon,
                          color: widget.item.iconColor ?? const Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.item.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.item.badge != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.item.badgeColor ??
                                          const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.item.badge!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Expand/Action Button
                      if (widget.item.actions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: const Color(0xFF2563EB),
                            ),
                            onPressed: _toggleExpand,
                          ),
                        ),
                    ],
                  ),
                ),

                // Expanded Actions
                if (widget.item.actions.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    child: SizeTransition(
                      sizeFactor: _expandController,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF9FAFB),
                          border: Border(
                            top: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widget.item.actions
                                .map(
                                  (action) => _ActionButton(
                                    label: action.label,
                                    icon: action.icon,
                                    color: action.color,
                                    onPressed: action.onPressed,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 22),
            onPressed: () {
              try {
                onPressed();
              } catch (e) {
                rethrow;
              }
            },
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
