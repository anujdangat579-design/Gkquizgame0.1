import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Outcome of a single answered (or skipped) question, for the
/// question-by-question breakdown below the summary.
enum QuestionOutcome { correct, incorrect, skipped }

/// One row of the report: the question, what the player answered, what
/// the correct answer was, and how long they took. UI-only local model —
/// mirrors what a real per-question result would carry once a match
/// results data layer exists, but isn't backed by one yet.
class QuestionReport {
  final int number;
  final String question;
  final String? yourAnswer;
  final String correctAnswer;
  final QuestionOutcome outcome;
  final int timeTakenSeconds;

  const QuestionReport({
    required this.number,
    required this.question,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.outcome,
    required this.timeTakenSeconds,
  });
}

/// Score Report screen — the detailed companion to `ResultPage`. Where
/// `ResultPage` gives the headline win/lose/draw and score comparison,
/// this screen answers "which questions did I get right, and where did
/// the time go" for a single player's own attempt.
///
/// UI only: [_report] is a fixed local list. Once a match-results data
/// layer exists, drive it from the real per-question outcomes for this
/// match, and wire [_handleShare] up to a real share/export (e.g. via the
/// existing PDF-generation approach used elsewhere in the app for
/// receipts/certificates, if this app has one) instead of the
/// placeholder snackbar.
///
/// Not yet added to any router; construct directly from `ResultPage`
/// (e.g. a "View full report" action) once that wiring exists.
class ScoreReportPage extends StatelessWidget {
  final int score;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final String averageTimeLabel;
  final List<QuestionReport> report;

  const ScoreReportPage({
    super.key,
    required this.score,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.averageTimeLabel,
    required this.report,
  });

  int get _totalQuestions => correctCount + incorrectCount + skippedCount;
  double get _accuracy => _totalQuestions == 0 ? 0 : correctCount / _totalQuestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share',
            onPressed: () => _handleShare(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SummaryCard(
            score: score,
            accuracy: _accuracy,
            averageTimeLabel: averageTimeLabel,
            totalQuestions: _totalQuestions,
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: _CountChip(
                  label: 'Correct',
                  count: correctCount,
                  color: context.semanticColors.success,
                  container: context.semanticColors.successContainer,
                  onContainer: context.semanticColors.onSuccessContainer,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CountChip(
                  label: 'Incorrect',
                  count: incorrectCount,
                  color: Theme.of(context).colorScheme.error,
                  container: Theme.of(context).colorScheme.errorContainer,
                  onContainer: Theme.of(context).colorScheme.onErrorContainer,
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CountChip(
                  label: 'Skipped',
                  count: skippedCount,
                  color: context.semanticColors.neutral,
                  container: context.semanticColors.neutralContainer,
                  onContainer: Theme.of(context).colorScheme.onSurfaceVariant,
                  icon: Icons.remove_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text('Question breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          for (final item in report) ...[
            _QuestionReportTile(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  void _handleShare(BuildContext context) {
    // TODO(reports-feature): replace with a real share/export (PDF or
    // otherwise) once that layer exists. Placeholder so the action isn't
    // a dead tap target.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sharing isn't wired up yet")),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int score;
  final double accuracy;
  final String averageTimeLabel;
  final int totalQuestions;

  const _SummaryCard({
    required this.score,
    required this.accuracy,
    required this.averageTimeLabel,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your score',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.85)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'points',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.85)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Accuracy',
                  value: '${(accuracy * 100).round()}%',
                  color: colorScheme.onPrimary,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Avg. time / Q',
                  value: averageTimeLabel,
                  color: colorScheme.onPrimary,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Questions',
                  value: '$totalQuestions',
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.85))),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color container;
  final Color onContainer;
  final IconData icon;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.container,
    required this.onContainer,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: onContainer),
          const SizedBox(height: AppSpacing.xs),
          Text('$count', style: theme.textTheme.titleMedium?.copyWith(color: onContainer, fontWeight: FontWeight.w700)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: onContainer)),
        ],
      ),
    );
  }
}

class _QuestionReportTile extends StatelessWidget {
  final QuestionReport item;

  const _QuestionReportTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    final (statusColor, statusIcon, statusLabel) = switch (item.outcome) {
      QuestionOutcome.correct => (semantic.success, Icons.check_circle, 'Correct'),
      QuestionOutcome.incorrect => (colorScheme.error, Icons.cancel, 'Incorrect'),
      QuestionOutcome.skipped => (semantic.neutral, Icons.remove_circle, 'Skipped'),
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          leading: Icon(statusIcon, color: statusColor),
          title: Text(
            'Q${item.number}. ${item.question}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$statusLabel · ${item.timeTakenSeconds}s',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          children: [
            _AnswerRow(
              label: 'Your answer',
              value: item.yourAnswer ?? 'Not answered',
              color: item.outcome == QuestionOutcome.correct ? semantic.success : colorScheme.error,
              muted: item.yourAnswer == null,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (item.outcome != QuestionOutcome.correct)
              _AnswerRow(
                label: 'Correct answer',
                value: item.correctAnswer,
                color: semantic.success,
                muted: false,
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool muted;

  const _AnswerRow({required this.label, required this.value, required this.color, required this.muted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted ? colorScheme.onSurfaceVariant : color,
              fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
