import 'package:flutter/material.dart';

/// Centered spinner for full-page or full-section loading states.
class LoadingIndicator extends StatelessWidget {
  final double strokeWidth;

  const LoadingIndicator({super.key, this.strokeWidth = 4});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(strokeWidth: strokeWidth));
  }
}

/// Small inline spinner sized to sit inside a button, next to text, etc.
class InlineLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const InlineLoadingIndicator({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
    );
  }
}
