import 'package:flutter/material.dart';

/// Single source of truth for the app's type scale.
///
/// No custom font is bundled (see `pubspec.yaml` — no `fonts:` section),
/// so every style here uses the platform default family and only
/// specifies size / weight / height / letter-spacing. If a brand font is
/// added later, set `fontFamily` once in [textTheme]'s `.apply()` call in
/// `light_theme.dart` / `dark_theme.dart` rather than touching every
/// style below.
///
/// Mirrors Material 3's 15-role type scale so every built-in widget
/// (AppBar title, ListTile title/subtitle, Card text, etc.) picks these
/// up automatically with zero per-widget overrides. Colors are
/// deliberately absent — `ThemeData.textTheme` colors itself from
/// `colorScheme` (onSurface/onSurfaceVariant), so hardcoding a color here
/// would break dark mode. Any widget that needs a color other than the
/// default reads `Theme.of(context).textTheme.X` and copies with a
/// `colorScheme` role, never a literal `Color`.
class AppTypography {
  AppTypography._();

  // ---------------------------------------------------------------------
  // Display — largest text, short and infrequent. Not really used in an
  // admin CRUD app like this one; kept for scale completeness.
  // ---------------------------------------------------------------------
  static const displayLarge = TextStyle(
    fontSize: 57, height: 64 / 57, fontWeight: FontWeight.w400, letterSpacing: -0.25,
  );
  static const displayMedium = TextStyle(
    fontSize: 45, height: 52 / 45, fontWeight: FontWeight.w400,
  );
  static const displaySmall = TextStyle(
    fontSize: 36, height: 44 / 36, fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------
  // Headline — page-level headers (e.g. empty-state heading).
  // ---------------------------------------------------------------------
  static const headlineLarge = TextStyle(
    fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w400,
  );
  static const headlineMedium = TextStyle(
    fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w400,
  );
  static const headlineSmall = TextStyle(
    fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------
  // Title — AppBar title, dialog title, section headers, form page title.
  // ---------------------------------------------------------------------
  static const titleLarge = TextStyle(
    fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w500,
  );
  static const titleMedium = TextStyle(
    fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, letterSpacing: 0.15,
  );
  static const titleSmall = TextStyle(
    fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
  );

  // ---------------------------------------------------------------------
  // Body — CompetitionCard description, form field values, dialog copy.
  // ---------------------------------------------------------------------
  static const bodyLarge = TextStyle(
    fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400, letterSpacing: 0.15,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400, letterSpacing: 0.25,
  );
  static const bodySmall = TextStyle(
    fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,
  );

  // ---------------------------------------------------------------------
  // Label — buttons, chips, input labels, date range caption on
  // CompetitionCard.
  // ---------------------------------------------------------------------
  static const labelLarge = TextStyle(
    fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
  );
  static const labelMedium = TextStyle(
    fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,
  );
  static const labelSmall = TextStyle(
    fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
  );

  /// The full `TextTheme` built from the styles above. Passed into
  /// `ThemeData.textTheme` and then `.apply(bodyColor:, displayColor:)`'d
  /// with roles from `colorScheme` in each theme file, so light/dark
  /// colors stay correct without duplicating this scale per mode.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
