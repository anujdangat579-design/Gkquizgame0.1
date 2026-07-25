import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/leaderboard.dart';
import '../../domain/usecases/get_leaderboard.dart';
import 'leaderboard_state.dart';

/// `ref.watch(leaderboardNotifierProvider)` gives the current
/// [LeaderboardState]; `ref.read(...notifier)` gives access to
/// [loadLeaderboard]. Use case comes from get_it (`sl`) — same split as
/// `quizNotifierProvider`.
final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(getLeaderboard: sl());
});

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final GetLeaderboard getLeaderboard;

  LeaderboardNotifier({required this.getLeaderboard}) : super(const LeaderboardState());

  /// Fetches the leaderboard for [range], replacing whatever board was
  /// previously loaded — mirrors `LeaderboardPage`'s old behavior of
  /// switching the segmented control and expecting fresh rankings for
  /// that window, rather than filtering a single fixed local list.
  Future<void> loadLeaderboard({required LeaderboardRange range}) async {
    state = state.copyWith(viewState: LeaderboardViewState.loading, range: range, clearError: true);

    final result = await getLeaderboard(GetLeaderboardParams(range: range));

    result.fold(
      (failure) {
        AppLogger.warning('loadLeaderboard failed: ${failure.message}', tag: 'Leaderboard');
        state = state.copyWith(viewState: LeaderboardViewState.error, errorMessage: failure.message);
      },
      (board) {
        state = state.copyWith(viewState: LeaderboardViewState.loaded, board: board, clearError: true);
      },
    );
  }
}
