import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

ThemeData darkTheme({ColorScheme? dynamicScheme}) {
  // final scheme = dynamicScheme ??
  //     ColorScheme.fromSeed(
  //       seedColor: const Color(0xFFB8DF54),
  //       brightness: Brightness.dark,
  //     );
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF64D3FF),
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme.harmonized(),
    appBarTheme: const AppBarTheme(),
    inputDecorationTheme: inputDecoration(),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      year2023: false,
    ),
  );
}

ThemeData lightTheme({ColorScheme? dynamicScheme}) {
  // final scheme = dynamicScheme ??
  //     ColorScheme.fromSeed(
  //       seedColor: const Color(0xFFB8DF54),
  //       brightness: Brightness.light,
  //     );
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF64D3FF),
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme.harmonized(),
    appBarTheme: const AppBarTheme(),
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
