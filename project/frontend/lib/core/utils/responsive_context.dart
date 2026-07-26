import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

enum DeviceType { mobile, tablet, desktop }

/// Quick responsive checks anywhere you have a `BuildContext`, without
/// wrapping every widget in a `LayoutBuilder`. Use `ResponsiveBuilder`
/// instead when a widget needs to rebuild reactively as width crosses a
/// breakpoint (e.g. inside a resizable pane); this extension is for the
/// common case of "read it once during build".
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  DeviceType get deviceType {
    final width = screenWidth;
    if (width >= Breakpoints.tablet) return DeviceType.desktop;
    if (width >= Breakpoints.mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Picks whichever value matches the current width. Only `mobile` is
  /// required; omitted `tablet`/`desktop` fall back to the next size down,
  /// so `context.responsive(mobile: 1)` alone is always safe to call.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}
