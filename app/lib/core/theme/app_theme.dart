import 'package:flutter/material.dart';

/// Status colours. Always pair them with an icon (CLAUDE.md rule 4):
/// green + tick = confirmed, amber + clock = pending, red + warning = hazard.
abstract final class AppColors {
  static const brand = Color(0xFF1B5E20);
  static const confirmed = Color(0xFF1B7F3B);
  static const pending = Color(0xFFB26A00);
  static const hazard = Color(0xFFC62828);
}

/// Big-button, high-contrast Material 3 theme for low-literacy users.
abstract final class AppTheme {
  /// Smallest allowed touch target, in dp (CLAUDE.md rule 2).
  static const double minTouch = 56;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      contrastLevel: 1.0,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    const buttonSize = Size(minTouch, minTouch);
    const buttonText = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return base.copyWith(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 20),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: buttonSize, iconSize: 32),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 64,
        // A title style replaces the default one completely, so it must
        // carry its own colour (without it the title was white on white).
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
