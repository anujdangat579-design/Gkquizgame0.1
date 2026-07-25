/// Spacing and shape tokens shared by both themes and any widget that
/// needs consistent gaps/radii without inventing its own magic numbers.
///
/// Mirrors the numbers that were already scattered through
/// `light_theme.dart` / `dark_theme.dart` (12/8/10/16/4px radii and
/// paddings) — pulling them here means changing the app's corner
/// rounding or padding rhythm is a one-file edit instead of a grep.
class AppSpacing {
  AppSpacing._();

  // Base 4px grid.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;   // inputs, chips, snackbars
  static const double md = 10;  // buttons
  static const double lg = 12;  // cards
  static const double xl = 16;  // dialogs
}
