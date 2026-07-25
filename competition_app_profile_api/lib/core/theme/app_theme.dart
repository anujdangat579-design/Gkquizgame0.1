import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Facade `app.dart` actually imports. Keeps each mode's `ThemeData` in
/// its own file (`light_theme.dart`, `dark_theme.dart`) so this class
/// stays a one-line-per-mode lookup table. The actual composition of
/// each theme (shape, spacing, typography — everything but color) is
/// shared between both via `buildAppTheme` in `app_theme_builder.dart`.
class AppTheme {
  AppTheme._();

  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;
}
