import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

ThemeData dark_nahcon({ColorScheme? dynamicScheme}) {

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF64D3FF),
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
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: scheme.surfaceContainerLow,
      contentTextStyle: TextStyle(color: scheme.onSurface)
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.linux: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.macOS: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.windows: const PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData light_nahcon({ColorScheme? dynamicScheme}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF64D3FF),
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  );
  return ThemeData(
    colorScheme: scheme.harmonized(),
    appBarTheme: AppBarTheme(scrolledUnderElevation: 0,),
    inputDecorationTheme: inputDecoration(),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      year2023: false,
    ),
  );
}

InputDecorationTheme inputDecoration() {
  return const InputDecorationTheme(
    border: OutlineInputBorder(),
  );
}
