import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'app_theme_builder.dart';

/// The app's light `ThemeData`. Only decides *colors* — background,
/// `ColorScheme` (generated from the brand seed), and which semantic
/// palette to use. Shape, spacing, and typography are shared with dark
/// mode via `buildAppTheme` in `app_theme_builder.dart`, so the two files
/// can never drift apart on anything but color.
final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.seed,
  brightness: Brightness.light,
);

final ThemeData lightTheme = buildAppTheme(
  colorScheme: _lightColorScheme,
  // See the matching comment in dark_theme.dart: derive from the
  // ColorScheme's own `surface` so the scaffold sits on the same
  // seed-tinted tonal ramp as cards/surfaces, not an unrelated literal.
  scaffoldBackgroundColor: _lightColorScheme.surface,
  semanticColors: AppSemanticColors.light,
);
