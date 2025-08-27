import 'package:flutter/material.dart';

ThemeData darkTheme({ColorScheme? dynamicScheme}) {
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFB8DF54),
        brightness: Brightness.dark,
      );
  return ThemeData(
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(),
    inputDecorationTheme: inputDecoration(),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      year2023: false,
    ),
  );
}

ThemeData lightTheme({ColorScheme? dynamicScheme}) {
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFB8DF54),
        brightness: Brightness.light,
      );
  return ThemeData(
    colorScheme: scheme,
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
