import 'package:flutter/material.dart';

ThemeData get darkTheme {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB8DF54),
      brightness: Brightness.dark,
      // dynamicSchemeVariant: DynamicSchemeVariant.content,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: inputDecoration(),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      year2023: false,
    ),
  );
}

ThemeData get lightTheme {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB8DF54),
      // dynamicSchemeVariant: DynamicSchemeVariant.content,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: inputDecoration(),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      year2023: false,
    ),
  );
}

InputDecorationThemeData inputDecoration() {
  return InputDecorationThemeData(
    // filled: true,
    // alignLabelWithHint: true,
    border: OutlineInputBorder(),
  );
}
