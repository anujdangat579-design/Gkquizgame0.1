import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// FilledButton that shows a spinner instead of its label while [isLoading]
/// is true, and disables itself so the action can't be double-submitted.
/// Use for any form submit / mutating action button.
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? const InlineLoadingIndicator() : child,
    );
  }
}
