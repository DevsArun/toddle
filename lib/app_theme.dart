import 'package:flutter/material.dart';

/// Central place for colors, sizes and text styles.
/// Everything is intentionally large and high-contrast for toddlers.
class AppTheme {
  static const Color brand = Color(0xFFFF7043);
  static const Color brandDark = Color(0xFFE64A19);
  static const Color sky = Color(0xFF4FC3F7);
  static const Color sunshine = Color(0xFFFFD54F);
  static const Color grass = Color(0xFF81C784);
  static const Color paper = Color(0xFFFFFDF7);
  static const Color ink = Color(0xFF3E2723);

  /// Minimum tap target for small hands.
  static const double touchTarget = 72;
  static const double radius = 24;

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      fontFamily: null,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyMedium: TextStyle(fontSize: 18, color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(160, touchTarget),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  /// The palette shown to the child. Big, saturated, toddler friendly.
  static const List<Color> palette = <Color>[
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFFFFB300),
    Color(0xFFFFEB3B),
    Color(0xFF7CB342),
    Color(0xFF26A69A),
    Color(0xFF29B6F6),
    Color(0xFF3949AB),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF546E7A),
    Color(0xFFFFCCBC),
    Color(0xFFFFFFFF),
    Color(0xFF212121),
  ];
}
