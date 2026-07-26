import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'app_theme_builder.dart';

/// The app's dark `ThemeData`. Mirrors `light_theme.dart` — only colors
/// differ; shape/spacing/typography come from the shared `buildAppTheme`
/// in `app_theme_builder.dart`.
final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.seed,
  brightness: Brightness.dark,
);

final ThemeData darkTheme = buildAppTheme(
  colorScheme: _darkColorScheme,
  // Material 3 tints `surface` toward the seed color rather than using a
  // neutral grey — a flat `0xFF121212` scaffold behind seed-tinted cards
  // (`colorScheme.surfaceContainer`) would show a visible seam. Using
  // `colorScheme.surface` here keeps the scaffold and every elevated
  // surface on the same tonal ramp.
  scaffoldBackgroundColor: _darkColorScheme.surface,
  semanticColors: AppSemanticColors.dark,
);
