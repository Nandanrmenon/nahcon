import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB8DF54),
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.content,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      scaffoldBackgroundColor: Colors.black);
}
