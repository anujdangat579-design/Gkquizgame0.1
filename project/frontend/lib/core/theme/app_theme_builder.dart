import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds a complete `ThemeData` from just the pieces that actually
/// differ between light and dark: a `ColorScheme`, a scaffold background,
/// and a set of semantic status colors.
///
/// Every component theme below (buttons, cards, inputs, dialogs, ...) was
/// previously copy-pasted verbatim into both `light_theme.dart` and
/// `dark_theme.dart` — identical shapes/paddings/elevations, colors
/// supplied implicitly via `colorScheme`. That duplication was a trap:
/// changing a card's corner radius meant remembering to edit it in two
/// files. Centralizing it here means `light_theme.dart` / `dark_theme.dart`
/// now only decide colors; everything about the app's *shape* lives once,
/// in [buildAppTheme].
ThemeData buildAppTheme({
  required ColorScheme colorScheme,
  required Color scaffoldBackgroundColor,
  required AppSemanticColors semanticColors,
}) {
  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,

    // Structure (size/weight/height) comes from AppTypography; `.apply()`
    // colors every role from this scheme so text stays correct in both
    // modes without a second copy of the type scale.
    textTheme: AppTypography.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
    ),

    dividerTheme: const DividerThemeData(space: 1, thickness: 1),

    extensions: [semanticColors],
  );
}
