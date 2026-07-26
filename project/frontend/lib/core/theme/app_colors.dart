import 'package:flutter/material.dart';

/// Static color tokens for the app.
///
/// This file holds two kinds of colors:
///  1. [seed] — the single brand color both `ColorScheme`s (light + dark)
///     are generated from via `ColorScheme.fromSeed`. Change it here, not
///     in each theme file, and every Material color (primary, surface,
///     container variants, etc.) stays in sync automatically.
///  2. Semantic status colors (success/warning/info) — Material 3's
///     generated scheme only gives us `error`, so these fill the gap for
///     the other meanings this app needs (e.g. "competition enabled").
///     Each has a light/dark pair so contrast stays correct in both modes,
///     matching how Flutter pairs `primary`/`onPrimary`,
///     `primaryContainer`/`onPrimaryContainer`, etc.
///
/// Don't reference these statics directly in widgets — use
/// `Theme.of(context).colorScheme` for Material roles and
/// `context.semanticColors` (see `app_semantic_colors.dart`) for
/// success/warning/info. That keeps every color access theme-aware and
/// swappable in one place.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Brand seed — drives ColorScheme.fromSeed in light_theme.dart /
  // dark_theme.dart. This is the one color to change for a rebrand.
  // ---------------------------------------------------------------------
  static const Color seed = Color(0xFF3D5AFE);

  // ---------------------------------------------------------------------
  // Success (e.g. "enabled" status, successful save/create)
  // ---------------------------------------------------------------------
  static const Color successLight = Color(0xFF2E7D32);
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color successContainerLight = Color(0xFFC8E6C9);
  static const Color onSuccessContainerLight = Color(0xFF1B5E20);

  static const Color successDark = Color(0xFF81C784);
  static const Color onSuccessDark = Color(0xFF0D3D12);
  static const Color successContainerDark = Color(0xFF1B5E20);
  static const Color onSuccessContainerDark = Color(0xFFC8E6C9);

  // ---------------------------------------------------------------------
  // Warning (e.g. competition ending soon, unsaved changes)
  // ---------------------------------------------------------------------
  static const Color warningLight = Color(0xFFED6C02);
  static const Color onWarningLight = Color(0xFFFFFFFF);
  static const Color warningContainerLight = Color(0xFFFFE0B2);
  static const Color onWarningContainerLight = Color(0xFFE65100);

  static const Color warningDark = Color(0xFFFFB74D);
  static const Color onWarningDark = Color(0xFF4A2800);
  static const Color warningContainerDark = Color(0xFFE65100);
  static const Color onWarningContainerDark = Color(0xFFFFE0B2);

  // ---------------------------------------------------------------------
  // Info (e.g. neutral banners, tips)
  // ---------------------------------------------------------------------
  static const Color infoLight = Color(0xFF0288D1);
  static const Color onInfoLight = Color(0xFFFFFFFF);
  static const Color infoContainerLight = Color(0xFFB3E5FC);
  static const Color onInfoContainerLight = Color(0xFF01579B);

  static const Color infoDark = Color(0xFF4FC3F7);
  static const Color onInfoDark = Color(0xFF00344D);
  static const Color infoContainerDark = Color(0xFF01579B);
  static const Color onInfoContainerDark = Color(0xFFB3E5FC);

  // ---------------------------------------------------------------------
  // Neutral / disabled status (e.g. "disabled" competition, inactive item)
  // Kept here rather than pulled from colorScheme.surfaceContainerHighest
  // so it reads consistently wherever a status pill/avatar needs it.
  // ---------------------------------------------------------------------
  static const Color neutralLight = Color(0xFF757575);
  static const Color neutralContainerLight = Color(0xFFE0E0E0);

  static const Color neutralDark = Color(0xFFBDBDBD);
  static const Color neutralContainerDark = Color(0xFF424242);
}
