import 'package:flutter/material.dart';

class ResponsiveGrid {
  static int columnCount(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    return 2;
  }

  static bool isDesktop(BoxConstraints constraints) =>
      constraints.maxWidth > 600;

  static const double posterAspectRatio = 0.7;
  static const double gridSpacing = 8.0;
}
