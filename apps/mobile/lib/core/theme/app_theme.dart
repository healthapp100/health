import 'package:flutter/material.dart';

/// Color/typography direction from BLUEPRINT.md §4.4: blues/greens/soft-white read as
/// trustworthy and calm in health UI; avoid harsh pure black-on-white for long-form education
/// content read by older/at-risk users. Tabular (fixed-width) figures are used wherever lab
/// values/dosages are displayed, to prevent dosage misreading.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1D6F63); // calm teal-green
  static const Color secondary = Color(0xFF2D6CDF); // trustworthy blue
  static const Color surfaceWarm = Color(0xFFFBFAF7); // soft warm-white, not pure white
  static const Color textPrimary = Color(0xFF2A2E2D); // soft dark-gray, not pure black
  static const Color danger = Color(0xFFB3261E);
  static const Color success = Color(0xFF1E8E5A);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.light,
      surface: surfaceWarm,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceWarm,
      textTheme: _textTheme(textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWarm,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme.onSurface),
    );
  }

  static TextTheme _textTheme(Color base) {
    // Tabular figures for anything numeric-heavy (vitals, dosages, lab values) — a patient-safety
    // detail called out explicitly in BLUEPRINT.md §4.4.
    const tabularFeature = [FontFeature.tabularFigures()];
    return TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: base),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, color: base),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: base),
      bodyLarge: TextStyle(color: base, height: 1.4),
      bodyMedium: TextStyle(color: base, height: 1.4),
      labelLarge: TextStyle(
        color: base,
        fontFeatures: tabularFeature,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
