import 'package:flutter/material.dart';

/// Color/typography direction from BLUEPRINT.md §4.4: blues/greens/soft-white read as
/// trustworthy and calm in health UI; avoid harsh pure black-on-white for long-form education
/// content read by older/at-risk users. Tabular (fixed-width) figures are used wherever lab
/// values/dosages are displayed, to prevent dosage misreading.
///
/// Accessibility pass: light and dark now share one component-theme builder so cards, buttons,
/// and inputs look identical in shape/elevation regardless of brightness — only colors differ.
/// `SemanticColors` fills the one gap Material 3's ColorScheme has no slot for ("warning", used
/// by StatusChip for pending/requested states) with a light/dark-correct pair instead of a
/// hardcoded hex that would fail contrast in dark mode.
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

    return _base(colorScheme, textPrimary).copyWith(
      scaffoldBackgroundColor: surfaceWarm,
      extensions: const [
        SemanticColors(
          warningContainer: Color(0xFFFFF1C2),
          onWarningContainer: Color(0xFF6B4E00),
        ),
      ],
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.dark,
    );

    return _base(colorScheme, colorScheme.onSurface).copyWith(
      extensions: const [
        SemanticColors(
          warningContainer: Color(0xFF4A3B00),
          onWarningContainer: Color(0xFFFFE08A),
        ),
      ],
    );
  }

  /// Shared shape/elevation/component styling — the part that must stay IDENTICAL between light
  /// and dark so switching theme never changes layout, only color. Only `ThemeData`'s color
  /// inputs (colorScheme, text color) vary per brightness.
  static ThemeData _base(ColorScheme colorScheme, Color textColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          minimumSize: const Size(48, 48), // WCAG 2.5.5 / Material minimum touch target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color base) {
    // Tabular figures for anything numeric-heavy (vitals, dosages, lab values) — a patient-safety
    // detail called out explicitly in BLUEPRINT.md §4.4. Sizes follow Material 3 defaults, which
    // already clear WCAG AA minimums at 100% system font scale and scale correctly with the
    // user's OS text-size setting (never clamped by this app).
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

/// Fills Material 3's missing "warning" semantic slot (ColorScheme only has primary/secondary/
/// tertiary/error) with a light/dark-correct color pair, so StatusChip's warning tone (used for
/// "requested"/"ordered" — pending states) never hardcodes a color that would fail contrast or
/// look wrong when the OS switches brightness.
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color warningContainer;
  final Color onWarningContainer;

  const SemanticColors({required this.warningContainer, required this.onWarningContainer});

  @override
  SemanticColors copyWith({Color? warningContainer, Color? onWarningContainer}) {
    return SemanticColors(
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
    );
  }
}
