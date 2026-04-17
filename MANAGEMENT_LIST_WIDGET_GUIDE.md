# Modern Management List Widget Guide

## Overview

A clean, modern list widget system has been implemented for all management screens in the QRmed application. This provides a consistent, professional UI/UX across all management interfaces with expandable action buttons and beautiful styling.

## Components

### 1. **ManagementListWidget**
The main list container that displays items with:
- Loading states
- Empty message displays
- Smooth scrolling
- Responsive padding

### 2. **ManagementListItem**
Data class for list items with properties:
- `id` (String) - Unique identifier
- `title` (String) - Item title
- `subtitle` (String) - Item subtitle/description
- `icon` (IconData) - Leading icon
- `iconColor` (Color?) - Icon background color (default: blue)
- `actions` (List<ManagementAction>) - Available actions
- `badge` (String?) - Optional status badge
- `badgeColor` (Color?) - Badge background color
- `onTap` (VoidCallback?) - Tap handler

### 3. **ManagementAction**
Data class for individual actions with:
- `label` (String) - Action label (displayed below icon)
- `icon` (IconData) - Action icon
- `color` (Color) - Icon and label color
- `onPressed` (VoidCallback) - Action callback

## Features

### Visual Design
- **Clean Cards**: Rounded corners (14px radius) with subtle shadows
- **Icon Indicators**: Colored icon backgrounds for quick identification
- **Status Badges**: Optional badges for status display
- **Dark Mode**: Full support with automatic theme detection
- **Smooth Animations**: Expandable actions with 300ms animation

### Action System
- **Expandable Actions**: Click expand button to reveal actions
- **Color-Coded**: Each action has its own color for quick visual identification
  - Blue: View/Details
  - Green: Edit
  - Red: Delete
  - Purple: Export
- **Vertical Layout**: Actions stack vertically with labels for clarity

### Responsive
- Adapts to different screen sizes
- Proper padding and margins for comfortable spacing
- Ellipsis text overflow handling

## Implementation Examples

### Manage Employees Screen
```dart
ManagementListWidget(
  items: _employees
      .map(
        (e) => ManagementListItem(
          id: e.id,
          title: e.name,
          subtitle: '${e.role} • ${e.email}',
          icon: Icons.person,
          iconColor: const Color(0xFF2563EB),
          actions: [
            ManagementAction(
              label: 'View',
              icon: Icons.remove_red_eye,
              color: const Color(0xFF2563EB),
              onPressed: () { /* View logic */ },
            ),
            ManagementAction(
              label: 'Edit',
              icon: Icons.edit,
              color: const Color(0xFF16A34A),
              onPressed: () { /* Edit logic */ },
            ),
            ManagementAction(
              label: 'Delete',
              icon: Icons.delete,
              color: const Color(0xFFDC2626),
              onPressed: () { /* Delete logic */ },
            ),
          ],
        ),
      )
      .toList(),
  emptyMessage: 'No employees found',
)
```

### Updated Screens

The following management screens have been updated to use the modern widget:

1. **manage_employees_screen.dart** ✅
   - Icons: Person (blue)
   - Actions: View, Edit, Delete
   - Subtitle: Role • Email

2. **manage_customers_screen.dart** ✅
   - Icons: Person outline (green)
   - Actions: View, Edit, Delete
   - Subtitle: Phone • Email

3. **manage_equipments_screen.dart** ✅
   - Icons: Devices (red)
   - Actions: Export, View, Edit, Delete
   - Badge: Status (color-coded)
   - Subtitle: Serial • Department

4. **manage_tickets_screen.dart** ✅
   - Icons: Ticket (status-colored)
   - Actions: View, Edit, Delete
   - Badge: Status (color-coded)
   - Subtitle: Raised By • Date

## Color Palette

### Status Colors
- **Working/Active**: `#16A34A` (Green)
- **Maintenance/In Progress**: `#F59E0B` (Amber)
- **Inactive/Closed**: `#6B7280` (Gray)
- **Error/Delete**: `#DC2626` (Red)
- **Info**: `#2563EB` (Blue)
- **Secondary**: `#7C3AED` (Purple)

### UI Colors
- **Primary Blue**: `#2563EB`
- **Light Gray Background**: `#F9FAFB`
- **Border**: `#E5E7EB`
- **Text Primary**: `#1F2937`
- **Text Secondary**: `#6B7280`

## Helper Widgets

### _DetailRow
Used in dialogs for displaying key-value pairs:
```dart
_DetailRow('Name', e.name),
_DetailRow('Email', e.email),
_DetailRow('Phone', e.phone),
```

## Animation Details

The expandable actions use a `SizeTransition` animation:
- **Duration**: 300ms
- **Curve**: Linear
- **Trigger**: Tap expand button or item

## Best Practices

1. **Icon Selection**: Use consistent icons across similar actions
2. **Ordering**: Place actions in logical order (View → Edit → Delete)
3. **Colors**: Use color conventions:
   - Blue for informational actions
   - Green for positive actions
   - Red for destructive actions
4. **Labels**: Keep action labels short (max 6 characters)
5. **Subtitles**: Combine relevant info with bullet separators

## Future Enhancements

Potential improvements for future versions:
- Swipe actions
- Multi-select mode
- Search/filter integration
- Custom action icons styling
- Animation customization
- Drag-and-drop reordering

## Migration Guide

To update existing management screens:

1. Add import:
   ```dart
   import '../widgets/management_list_widget.dart';
   ```

2. Replace ListView.builder with ManagementListWidget

3. Map data to ManagementListItem objects

4. Define ManagementAction callbacks

5. Extract detail dialogs if needed

## File Location

- **Widget File**: `lib/widgets/management_list_widget.dart`
- **Icon File**: (Included in Flutter Material)

## Dependencies

- Flutter Material Design
- Provider (existing)

No additional dependencies required!
