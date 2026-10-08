import 'package:flutter/material.dart';

/// Centralized, Material 3-compatible Notiq brand tokens.
class NotiqTheme {
  NotiqTheme._();

  static const violet = Color(0xFF635BFF);
  static const teal = Color(0xFF18B6A4);
  static const dark = Color(0xFF11182B);
  static const canvas = Color(0xFFF8F9FC);
  static const ink = Color(0xFF172038);
  static const muted = Color(0xFF667085);
  static const darkSurface = Color(0xFF1B2438);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: violet,
      brightness: brightness,
    ).copyWith(
      primary: violet,
      onPrimary: Colors.white,
      secondary: teal,
      surface: isDark ? darkSurface : Colors.white,
      onSurface: isDark ? const Color(0xFFF2F4FF) : ink,
    );

    final outline = isDark ? const Color(0xFF394158) : const Color(0xFFDDE2EC);
    final subtle = isDark ? const Color(0xFFABB6C9) : muted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? dark : canvas,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? dark : canvas,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        floatingLabelStyle: const TextStyle(color: violet),
        hintStyle: TextStyle(color: subtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: violet, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: violet,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: outline),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: violet.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: violet.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: outline,
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: scheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        bodyMedium: TextStyle(color: scheme.onSurface),
        bodySmall: TextStyle(color: subtle),
      ),
    );
  }
}
