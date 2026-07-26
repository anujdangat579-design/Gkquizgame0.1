import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../injection_container.dart';
import '../../domain/usecases/submit_winner_feedback.dart';
import 'winner_feedback_state.dart';

/// `ref.watch(winnerFeedbackNotifierProvider)` gives the current
/// [WinnerFeedbackState]; `ref.read(...notifier)` gives access to
/// [submit]. Use case comes from get_it (`sl`) — same split as
/// `quizNotifierProvider`.
final winnerFeedbackNotifierProvider =
    StateNotifierProvider<WinnerFeedbackNotifier, WinnerFeedbackState>((ref) {
  return WinnerFeedbackNotifier(submitWinnerFeedback: sl());
});

class WinnerFeedbackNotifier extends StateNotifier<WinnerFeedbackState> {
  final SubmitWinnerFeedback submitWinnerFeedback;

  WinnerFeedbackNotifier({required this.submitWinnerFeedback}) : super(const WinnerFeedbackState());

  /// Submits the winner's rating/comment/report for `matchId`. Returns
  /// true on success so `WinnerFeedbackPage` can navigate away; on
  /// failure, stashes the message in `state.errorMessage` and returns
  /// false so the page can show a retry affordance instead of assuming
  /// success like the old fixed-delay placeholder did.
  Future<bool> submit({
    required String matchId,
    required int rating,
    String? comment,
    required bool reportedOpponent,
    String? reportReason,
  }) async {
    state = state.copyWith(viewState: FeedbackViewState.submitting, clearError: true);

    final result = await submitWinnerFeedback(
      SubmitWinnerFeedbackParams(
        matchId: matchId,
        rating: rating,
        comment: comment,
        reportedOpponent: reportedOpponent,
        reportReason: reportReason,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(viewState: FeedbackViewState.error, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(viewState: FeedbackViewState.success, clearError: true);
        return true;
      },
    );
  }

  /// Resets back to idle so the page can dismiss an error state (e.g.
  /// once the user edits the form again) without a stale error message
  /// lingering in a later `ref.watch`.
  void resetError() {
    if (state.viewState == FeedbackViewState.error) {
      state = state.copyWith(viewState: FeedbackViewState.idle, clearError: true);
    }
  }
}
