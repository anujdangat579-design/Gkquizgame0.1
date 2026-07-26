import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../dashboard/routes/dashboard_routes.dart';
import '../providers/winner_feedback_notifier.dart';
import '../providers/winner_feedback_state.dart';

/// Post-match feedback, shown only to the winning player right after
/// `ResultPage`.
///
/// Winner-only by construction: this page doesn't check who won itself —
/// the caller (`ResultPage`, once its "Back to home" wiring is finished)
/// is responsible for only ever navigating here when `_Outcome.won`, and
/// sending losing/drawn players straight to Dashboard instead. A losing
/// player can still leave feedback later — that flow belongs under
/// Account → "My Feedback" (not built yet — `AccountPage` now shows a
/// real profile, but has no feedback list/section) rather than this
/// screen, which is specifically the "you just won, tell us about it"
/// moment, not a general-purpose feedback form.
///
/// [_handleSubmit] posts to `ApiConstants.matchFeedback` via
/// `WinnerFeedbackNotifier.submit`. On failure it shows the error with a
/// retry affordance instead of navigating away, since a dropped
/// submission shouldn't silently look like it succeeded.
class WinnerFeedbackPage extends ConsumerStatefulWidget {
  final String matchId;
  final String opponentName;

  const WinnerFeedbackPage({
    super.key,
    required this.matchId,
    required this.opponentName,
  });

  @override
  ConsumerState<WinnerFeedbackPage> createState() => _WinnerFeedbackPageState();
}

class _WinnerFeedbackPageState extends ConsumerState<WinnerFeedbackPage> {
  int _rating = 0;
  final _commentController = TextEditingController();

  bool _reportOpponent = false;
  final _reportReasonController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _reportReasonController.dispose();
    super.dispose();
  }

  bool _canSubmit(FeedbackViewState viewState) => _rating > 0 && viewState != FeedbackViewState.submitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;
    final feedbackState = ref.watch(winnerFeedbackNotifierProvider);
    final isSubmitting = feedbackState.viewState == FeedbackViewState.submitting;

    return PopScope(
      // Same forward-only philosophy as the quiz itself (see
      // QuestionNavigationBar's permanently-disabled Previous): once
      // you've won and reached this screen, there's nothing to go back
      // into — the match is already over.
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Rate your match')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: semantic.successContainer),
                child: Icon(Icons.emoji_events, size: 36, color: semantic.onSuccessContainer),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Nice win! \u{1F389}', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'How was your match against ${widget.opponentName}?',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text('Match experience', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              _StarRating(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text('Comment (optional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'What made the match fun \u2014 or what could be better?',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _ReportOpponentSection(
                opponentName: widget.opponentName,
                enabled: _reportOpponent,
                reasonController: _reportReasonController,
                onToggle: (value) => setState(() => _reportOpponent = value),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canSubmit(feedbackState.viewState) ? _handleSubmit : null,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(feedbackState.viewState == FeedbackViewState.error ? 'Try again' : 'Submit feedback'),
                ),
              ),
              if (_rating == 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    'Add a star rating to submit',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ] else if (feedbackState.viewState == FeedbackViewState.error) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    feedbackState.errorMessage ?? 'Couldn\u2019t submit feedback. Please try again.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final reportReason = _reportOpponent ? _reportReasonController.text.trim() : null;

    final succeeded = await ref.read(winnerFeedbackNotifierProvider.notifier).submit(
          matchId: widget.matchId,
          rating: _rating,
          comment: _commentController.text.trim(),
          reportedOpponent: _reportOpponent,
          reportReason: (reportReason == null || reportReason.isEmpty) ? null : reportReason,
        );

    if (!mounted) return;

    if (!succeeded) {
      // Error message is already shown inline below the button (see
      // build()) via the notifier's state — the button also flips to
      // "Try again" and stays enabled so the player can resubmit
      // without losing their rating/comment/report input.
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks! Your feedback has been submitted.')),
    );

    // Give the success snackbar a moment to actually be seen before
    // navigating away and disposing this screen.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // TODO(matchmaking-feature): once this page is reached via go_router
    // instead of a raw Navigator.push from ResultPage, prefer
    // `context.go` from a route context that's actually inside the
    // shell — this works today because GoRouter is app-wide, but revisit
    // once ResultPage/WinnerFeedbackPage get real routes of their own.
    context.go(DashboardRoutes.home);
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 36,
              color: i <= rating ? Colors.amber : colorScheme.outlineVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            splashRadius: 24,
          ),
      ],
    );
  }
}

/// Optional report flow, tucked below the main rating so it doesn't
/// compete with the (expected-to-be-common) positive-feedback path for
/// attention — most winners submitting feedback aren't reporting anyone.
class _ReportOpponentSection extends StatelessWidget {
  final String opponentName;
  final bool enabled;
  final TextEditingController reasonController;
  final ValueChanged<bool> onToggle;

  const _ReportOpponentSection({
    required this.opponentName,
    required this.enabled,
    required this.reasonController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onToggle(!enabled),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 20, color: colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Report $opponentName', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'e.g. cheating, abusive messages, or other unsportsmanlike behavior',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Reason (optional)'),
            ),
          ],
        ],
      ),
    );
  }
}
