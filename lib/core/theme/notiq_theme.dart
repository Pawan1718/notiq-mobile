import 'package:flutter/material.dart';

class NotiqTheme {
  NotiqTheme._();
  static const violet = Color(0xFF635BFF);
  static const teal = Color(0xFF18B6A4);
  static const dark = Color(0xFF11182B);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: violet),
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static ThemeData darkTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: violet, brightness: Brightness.dark),
        scaffoldBackgroundColor: dark,
      );
}
