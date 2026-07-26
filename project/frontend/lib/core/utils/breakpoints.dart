/// Width breakpoints in logical pixels. Matches Material 3's guidance for
/// compact / medium / expanded window size classes, which is what
/// `flutter run -d chrome` or an actual tablet/desktop build will hit
/// even though this app started phone-only.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
  // >= tablet is treated as desktop.
}
