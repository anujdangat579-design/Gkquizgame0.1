import 'package:flutter/widgets.dart';

import 'breakpoints.dart';
import 'responsive_context.dart';

typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context, DeviceType deviceType);

/// Rebuilds its child whenever available width crosses a breakpoint —
/// e.g. a resizable window, split-screen, or orientation change. Uses
/// `LayoutBuilder`'s constraints (the space this widget actually has)
/// rather than `MediaQuery` (the whole screen), so it also works inside
/// a panel that isn't full-width.
///
/// For the common "just read it once during build" case, prefer the
/// `context.isMobile` / `context.responsive(...)` extension instead —
/// it's cheaper and doesn't need this wrapper.
class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final DeviceType deviceType;
        if (constraints.maxWidth >= Breakpoints.tablet) {
          deviceType = DeviceType.desktop;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          deviceType = DeviceType.tablet;
        } else {
          deviceType = DeviceType.mobile;
        }
        return builder(context, deviceType);
      },
    );
  }
}
