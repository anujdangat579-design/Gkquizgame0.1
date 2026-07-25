import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Card for a single answer option (A/B/C/D) inside a quiz question.
///
/// Standalone and reusable: covers both a live, unrevealed selection
/// state (used in `QuizPage` while a question is still being answered)
/// and a revealed correct/incorrect state (useful for a post-match
/// review screen showing what the right answer was) — controlled purely
/// by [isSelected] and [isCorrect] rather than two separate widgets, so
/// the same visual language carries from "picking an answer" to
/// "reviewing an answer" without reinventing it.
///
/// State precedence when [isCorrect] is non-null ("revealed"):
///  - this option is the correct one → green, regardless of selection
///  - this option was selected but wrong → red
///  - otherwise → neutral, dimmed
/// When [isCorrect] is null ("unrevealed", the normal in-quiz case):
///  - selected → primary highlight
///  - otherwise → neutral
///
/// UI only: purely presentational, no domain entity dependency.
class AnswerOptionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isLocked;

  /// `null` = not yet revealed (normal live-quiz state). `true`/`false`
  /// marks this specific option as the correct/incorrect one once an
  /// answer has been revealed (e.g. on a review screen).
  final bool? isCorrect;

  final VoidCallback? onTap;

  const AnswerOptionCard({
    super.key,
    required this.label,
    required this.text,
    this.isSelected = false,
    this.isLocked = false,
    this.isCorrect,
    this.onTap,
  });

  bool get _isRevealed => isCorrect != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    late final Color background;
    late final Color borderColor;
    late final Color badgeBg;
    late final Color badgeFg;
    late final Color textColor;
    Widget? trailingIcon;
    double borderWidth = 1;

    if (_isRevealed) {
      if (isCorrect == true) {
        background = semantic.successContainer;
        borderColor = semantic.success;
        badgeBg = semantic.success;
        badgeFg = semantic.onSuccess;
        textColor = semantic.onSuccessContainer;
        borderWidth = 2;
        trailingIcon = Icon(Icons.check_circle, color: semantic.success, size: 20);
      } else if (isSelected) {
        background = colorScheme.errorContainer;
        borderColor = colorScheme.error;
        badgeBg = colorScheme.error;
        badgeFg = colorScheme.onError;
        textColor = colorScheme.onErrorContainer;
        borderWidth = 2;
        trailingIcon = Icon(Icons.cancel, color: colorScheme.error, size: 20);
      } else {
        background = colorScheme.surface;
        borderColor = colorScheme.outlineVariant;
        badgeBg = colorScheme.surfaceContainerHighest;
        badgeFg = colorScheme.onSurfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
      }
    } else if (isSelected) {
      background = colorScheme.primaryContainer;
      borderColor = colorScheme.primary;
      badgeBg = colorScheme.primary;
      badgeFg = colorScheme.onPrimary;
      textColor = colorScheme.onPrimaryContainer;
      borderWidth = 2;
      trailingIcon = Icon(Icons.check_circle, color: colorScheme.primary, size: 20);
    } else {
      background = colorScheme.surface;
      borderColor = colorScheme.outlineVariant;
      badgeBg = colorScheme.surfaceContainerHighest;
      badgeFg = colorScheme.onSurfaceVariant;
      textColor = colorScheme.onSurface;
    }

    final dimmed = _isRevealed && isCorrect == false && !isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: (isSelected && !_isRevealed) || (isCorrect == true)
            ? [
                BoxShadow(
                  color: borderColor.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: dimmed ? 0.6 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: (isLocked || _isRevealed) ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(color: badgeFg, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: (isSelected || isCorrect == true) ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) trailingIcon,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
