import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Optional difficulty tag shown on a [QuestionCard]. Kept separate from
/// `CompetitionDetailsPage`'s `_Difficulty` (entry-fee tiers picked
/// before joining) — this is a per-question label, not a match-level
/// setting, so the two aren't merged even though the names overlap.
enum QuestionDifficulty { easy, medium, hard }

extension on QuestionDifficulty {
  String get label {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }
}

/// Card presenting a single quiz question's text, with optional category
/// and difficulty tags above it.
///
/// Standalone and reusable: used as the question surface inside
/// `QuizPage` during a live match, but not coupled to it — also suitable
/// for a question-bank preview/review screen (e.g. reviewing bulk-CSV
/// imported questions in an admin flow) since it takes plain values
/// rather than a match-session model.
///
/// UI only: purely presentational, no domain entity dependency.
class QuestionCard extends StatelessWidget {
  final String question;
  final String? category;
  final QuestionDifficulty? difficulty;

  const QuestionCard({
    super.key,
    required this.question,
    this.category,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasTags = category != null || difficulty != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTags) ...[
            Row(
              children: [
                if (category != null) _CategoryTag(label: category!),
                if (category != null && difficulty != null) const SizedBox(width: AppSpacing.sm),
                if (difficulty != null) _DifficultyTag(difficulty: difficulty!),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            question,
            style: theme.textTheme.titleLarge?.copyWith(height: 1.35, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;

  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DifficultyTag extends StatelessWidget {
  final QuestionDifficulty difficulty;

  const _DifficultyTag({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    final (background, foreground) = switch (difficulty) {
      QuestionDifficulty.easy => (semantic.successContainer, semantic.onSuccessContainer),
      QuestionDifficulty.medium => (semantic.warningContainer, semantic.onWarningContainer),
      QuestionDifficulty.hard => (colorScheme.errorContainer, colorScheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        difficulty.label,
        style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
