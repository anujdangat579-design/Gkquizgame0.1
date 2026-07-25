import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';

/// Circular countdown ring that sweeps down as time elapses, shifting
/// color from primary → warning → error as it runs low — carries
/// urgency through color and motion rather than a bare number alone.
///
/// Standalone and reusable: used as the per-question timer in
/// `QuizPage`, but takes plain `secondsLeft`/`totalSeconds` rather than
/// anything quiz-specific, so it's equally suited to any other timed
/// action in the app (e.g. an OTP resend countdown, a queue timeout)
/// once one needs the same "ring that runs out" language.
///
/// UI only: purely presentational — driven by whatever `Timer`/stream
/// the caller uses to update `secondsLeft` each tick (see `QuizPage`'s
/// own `Timer.periodic` for the pattern), not by a timer of its own.
class CircularTimer extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final double size;
  final double strokeWidth;

  /// Overrides the default center label (`"$secondsLeft"`). Useful for
  /// e.g. showing "0:45" instead of a raw seconds count.
  final String Function(int secondsLeft)? labelBuilder;

  /// Absolute-seconds urgency thresholds, as an alternative to the default
  /// fraction-of-total coloring. When both are set, the ring turns
  /// [semanticColors.warning] once `secondsLeft < warnBelowSeconds` and
  /// [ColorScheme.error] once `secondsLeft < dangerBelowSeconds`. Leave
  /// null (the default) to keep the original 50%/25%-of-[totalSeconds]
  /// behavior — useful for callers (like an OTP resend countdown) where
  /// "danger" should scale with the countdown length rather than a fixed
  /// number of seconds.
  final int? warnBelowSeconds;
  final int? dangerBelowSeconds;

  const CircularTimer({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    this.size = 52,
    this.strokeWidth = 4,
    this.labelBuilder,
    this.warnBelowSeconds,
    this.dangerBelowSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    final fraction = totalSeconds == 0 ? 0.0 : secondsLeft / totalSeconds;
    final useAbsoluteThresholds = warnBelowSeconds != null && dangerBelowSeconds != null;
    final ringColor = useAbsoluteThresholds
        ? (secondsLeft < dangerBelowSeconds!
            ? colorScheme.error
            : secondsLeft < warnBelowSeconds!
                ? semantic.warning
                : colorScheme.primary)
        : fraction > 0.5
            ? colorScheme.primary
            : fraction > 0.25
                ? semantic.warning
                : colorScheme.error;
    final label = labelBuilder != null ? labelBuilder!(secondsLeft) : '$secondsLeft';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: fraction.clamp(0, 1)),
            duration: const Duration(milliseconds: 350),
            builder: (context, value, _) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: value,
                color: ringColor,
                trackColor: colorScheme.surfaceContainerHighest,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          Text(
            label,
            style: (size >= 72 ? theme.textTheme.titleMedium : theme.textTheme.titleSmall)?.copyWith(
              fontWeight: FontWeight.w700,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth - 1) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
