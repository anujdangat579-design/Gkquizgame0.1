import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../dashboard/routes/dashboard_routes.dart';
import 'opponent_found_page.dart' show QueuePlayer;
import 'score_report_page.dart';
import 'winner_feedback_page.dart';

/// Match outcome, derived from comparing scores rather than stored
/// directly — keeps `ResultPage` a pure function of the two scores it's
/// given instead of trusting a separately-passed-in verdict that could
/// drift out of sync with them.
enum _Outcome { won, lost, drawn }

extension on _Outcome {
  String get title {
    switch (this) {
      case _Outcome.won:
        return 'You won!';
      case _Outcome.lost:
        return 'Better luck next time';
      case _Outcome.drawn:
        return "It's a draw";
    }
  }

  IconData get icon {
    switch (this) {
      case _Outcome.won:
        return Icons.emoji_events;
      case _Outcome.lost:
        return Icons.sentiment_neutral_outlined;
      case _Outcome.drawn:
        return Icons.handshake_outlined;
    }
  }
}

/// Result screen — shown once both players finish all questions in
/// `QuizPage` (i.e. after its "Waiting for your opponent to finish..."
/// state resolves).
///
/// Takes plain scores/stats rather than the `MatchResult` domain entity
/// directly — `QuizPage` unpacks the fetched `MatchResult` (or its own
/// placeholder fallback, if that fetch failed) into these fields, so
/// this widget stays a pure function of the values it's given and
/// doesn't need to know where they came from. [_handlePlayAgain] and
/// the "Back to home" action are placeholders — wire them to real
/// navigation (e.g. back into `CategoryGrid` / `MainShellPage`'s
/// dashboard tab) once this sits behind a router. No prize-money figure
/// is shown here, consistent with `CompetitionDetailsPage`'s "no cash
/// prize" notice — this is a score/ranking outcome, not a payout screen.
class ResultPage extends StatelessWidget {
  final QueuePlayer you;
  final QueuePlayer opponent;
  final int yourScore;
  final int opponentScore;
  final int correctAnswers;
  final int totalQuestions;
  final String timeTakenLabel;
  final String category;
  final String matchId;

  /// Real per-question breakdown from the match result API, if the
  /// backend sent one alongside the summary (see `MatchResult`'s doc
  /// comment). Null falls back to synthesizing a placeholder from just
  /// `correctAnswers`/`totalQuestions`, same as before this existed.
  final List<QuestionReport>? questionBreakdown;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onBackToHome;

  const ResultPage({
    super.key,
    required this.you,
    required this.opponent,
    required this.yourScore,
    required this.opponentScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTakenLabel,
    required this.category,
    required this.matchId,
    this.questionBreakdown,
    this.onPlayAgain,
    this.onBackToHome,
  });

  _Outcome get _outcome {
    if (yourScore > opponentScore) return _Outcome.won;
    if (yourScore < opponentScore) return _Outcome.lost;
    return _Outcome.drawn;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;
    final outcome = _outcome;

    final outcomeColor = switch (outcome) {
      _Outcome.won => semantic.success,
      _Outcome.lost => colorScheme.error,
      _Outcome.drawn => semantic.info,
    };
    final outcomeContainer = switch (outcome) {
      _Outcome.won => semantic.successContainer,
      _Outcome.lost => colorScheme.errorContainer,
      _Outcome.drawn => semantic.infoContainer,
    };
    final onOutcomeContainer = switch (outcome) {
      _Outcome.won => semantic.onSuccessContainer,
      _Outcome.lost => colorScheme.onErrorContainer,
      _Outcome.drawn => semantic.onInfoContainer,
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _OutcomeBadge(outcome: outcome, color: outcomeColor, container: outcomeContainer, onContainer: onOutcomeContainer),
                    const SizedBox(height: AppSpacing.lg),
                    Text(outcome.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      category,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    _ScoreComparisonRow(
                      you: you,
                      opponent: opponent,
                      yourScore: yourScore,
                      opponentScore: opponentScore,
                      youWon: outcome == _Outcome.won,
                      opponentWon: outcome == _Outcome.lost,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.check_circle_outline,
                            label: 'Correct answers',
                            value: '$correctAnswers/$totalQuestions',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.schedule_outlined,
                            label: 'Time taken',
                            value: timeTakenLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _NoCashPrizeNotice(),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _handleViewFullReport(context),
                        icon: const Icon(Icons.assessment_outlined, size: 18),
                        label: const Text('View full score report'),
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleBackToHome(context),
                      child: const Text('Back to home'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPlayAgain,
                      child: const Text('Play again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Winner-only gate for feedback, kept here rather than in
  // WinnerFeedbackPage itself — see that page's doc comment.
  void _handleBackToHome(BuildContext context) {
    if (onBackToHome != null) {
      onBackToHome!();
      return;
    }

    if (_outcome == _Outcome.won) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WinnerFeedbackPage(matchId: matchId, opponentName: opponent.name),
        ),
      );
      return;
    }

    // Losing/drawn players skip winner feedback entirely. They can still
    // leave feedback later via Account → "My Feedback" (not built yet —
    // AccountPage now shows a real profile, but has no feedback section).
    //
    // TODO(matchmaking-feature): once ResultPage has a real route of its
    // own, this and WinnerFeedbackPage's post-submit navigation should
    // both go through the same "return to shell root" path rather than
    // each calling context.go independently.
    context.go(DashboardRoutes.home);
  }

  // Uses the real per-question breakdown from the match result API when
  // `questionBreakdown` was supplied; otherwise falls back to
  // synthesizing a placeholder from just the aggregate counts (same as
  // before the result API was wired in).
  void _handleViewFullReport(BuildContext context) {
    final incorrectCount = totalQuestions - correctAnswers;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScoreReportPage(
          score: yourScore,
          correctCount: correctAnswers,
          incorrectCount: incorrectCount < 0 ? 0 : incorrectCount,
          skippedCount: 0,
          averageTimeLabel: timeTakenLabel,
          report: questionBreakdown ??
              [
                for (int i = 0; i < totalQuestions; i++)
                  QuestionReport(
                    number: i + 1,
                    question: 'Question ${i + 1}',
                    yourAnswer: i < correctAnswers ? 'Correct option' : 'Other option',
                    correctAnswer: 'Correct option',
                    outcome: i < correctAnswers ? QuestionOutcome.correct : QuestionOutcome.incorrect,
                    timeTakenSeconds: 0,
                  ),
              ],
        ),
      ),
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  final _Outcome outcome;
  final Color color;
  final Color container;
  final Color onContainer;

  const _OutcomeBadge({
    required this.outcome,
    required this.color,
    required this.container,
    required this.onContainer,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: container,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.25), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Icon(outcome.icon, size: 48, color: onContainer),
      ),
    );
  }
}

class _ScoreComparisonRow extends StatelessWidget {
  final QueuePlayer you;
  final QueuePlayer opponent;
  final int yourScore;
  final int opponentScore;
  final bool youWon;
  final bool opponentWon;

  const _ScoreComparisonRow({
    required this.you,
    required this.opponent,
    required this.yourScore,
    required this.opponentScore,
    required this.youWon,
    required this.opponentWon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _PlayerScore(player: you, score: yourScore, label: 'You', isWinner: youWon),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'vs',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: _PlayerScore(player: opponent, score: opponentScore, label: 'Opponent', isWinner: opponentWon),
        ),
      ],
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final QueuePlayer player;
  final int score;
  final String label;
  final bool isWinner;

  const _PlayerScore({
    required this.player,
    required this.score,
    required this.label,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.all(isWinner ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isWinner ? Border.all(color: semantic.success, width: 2) : null,
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.secondaryContainer,
                backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
                child: player.photoUrl == null
                    ? Text(
                        player.initials,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
            if (isWinner)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: semantic.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(Icons.emoji_events, size: 14, color: semantic.onSuccess),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        Text(
          player.name,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$score',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text('points', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _NoCashPrizeNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.infoContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: semantic.onInfoContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Score-based result only — no cash prize is paid out for this competition.',
              style: theme.textTheme.bodySmall?.copyWith(color: semantic.onInfoContainer),
            ),
          ),
        ],
      ),
    );
  }
}
