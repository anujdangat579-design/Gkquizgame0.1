import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shown the instant the local player finishes their last question, for
/// the interval before the opponent also finishes.
///
/// This is deliberately a dead end with no actions: in a real-time,
/// server-authoritative match there's nothing left for this player to
/// do — no "next" question to move to (see [QuestionNavigationBar]'s
/// disabled `Previous`, same forward-only philosophy) and no result to
/// show yet, since the outcome depends on the opponent's still-pending
/// score. Once a live match layer exists, the caller should listen for
/// the opponent's completion event and transition straight to
/// `ResultPage` — this view has no button to make that transition
/// itself, so it never becomes a stale screen the player gets stuck on.
///
/// Standalone and reusable: used as `QuizPage`'s finished state, but
/// only needs a question count, not anything quiz-specific.
class QuizCompletedView extends StatelessWidget {
  final int total;

  const QuizCompletedView({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: semantic.successContainer,
                  boxShadow: [
                    BoxShadow(color: semantic.success.withOpacity(0.25), blurRadius: 24, spreadRadius: 2),
                  ],
                ),
                child: Icon(Icons.check_rounded, size: 44, color: semantic.onSuccessContainer),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Quiz completed!', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'All $total questions answered',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _WaitingForOpponentPill(),
          ],
        ),
      ),
    );
  }
}

/// Explicit "still waiting" status, rather than a bare spinner — makes
/// clear the delay is the opponent's match state, not the app hanging.
class _WaitingForOpponentPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Waiting for your opponent to finish...',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
