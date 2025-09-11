import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';

ThemeData darkTheme({ColorScheme? dynamicScheme}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kAppColor,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  );
  return ThemeData(
    colorScheme: scheme.harmonized(),
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: inputDecoration(),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      year2023: false,
      color: kAppColor,
    ),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: scheme.surfaceContainerLow,
        contentTextStyle: TextStyle(color: scheme.onSurface)),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    chipTheme: chipTheme(),
  );
}

ThemeData lightTheme({ColorScheme? dynamicScheme}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kAppColor,
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  );
  return ThemeData(
    colorScheme: scheme.harmonized(),
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: inputDecoration(),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: scheme.surfaceContainerLow,
        contentTextStyle: TextStyle(color: scheme.onSurface)),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      year2023: false,
      color: kAppColor,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    chipTheme: chipTheme(),
  );
}

ChipThemeData chipTheme() {
  return ChipThemeData(
    selectedColor: kAppColor.withAlpha(50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

InputDecorationTheme inputDecoration() {
  return InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
        borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16.0)),
    // border: OutlineInputBorder(),
  );
}
