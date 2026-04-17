import 'package:flutter/material.dart';

class ResponsiveUtils {
  static int getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4; // Large desktop
    } else if (width > 900) {
      return 3; // Desktop/Tablet landscape
    } else if (width > 600) {
      return 2; // Tablet portrait
    } else {
      return 2; // Mobile (keep 2 for tiles as they look better than 1 if not too wide)
    }
  }

  static double getChildAspectRatio(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 1.2; // Wider tiles on large screens
    } else if (width > 900) {
      return 1.1;
    } else if (width > 600) {
      return 1.0;
    } else {
      return 0.9; // Taller tiles on mobile
    }
  }
  
  static double getMaxWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 1100; // Constrain content width on very large screens
    }
    return double.infinity;
  }
}
