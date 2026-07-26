import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_match_history.dart';
import 'match_history_state.dart';

/// `ref.watch(matchHistoryNotifierProvider)` gives the current
/// [MatchHistoryState]; `ref.read(...notifier)` gives access to
/// [loadMatchHistory]. Use case comes from get_it (`sl`) — same split as
/// `competitionNotifierProvider`.
final matchHistoryNotifierProvider =
    StateNotifierProvider<MatchHistoryNotifier, MatchHistoryState>((ref) {
  return MatchHistoryNotifier(getMatchHistory: sl());
});

class MatchHistoryNotifier extends StateNotifier<MatchHistoryState> {
  final GetMatchHistory getMatchHistory;

  MatchHistoryNotifier({required this.getMatchHistory}) : super(const MatchHistoryState());

  Future<void> loadMatchHistory({int page = AppConstants.defaultPage}) async {
    state = state.copyWith(viewState: MatchHistoryViewState.loading, clearError: true);

    final result = await getMatchHistory(GetMatchHistoryParams(page: page));

    result.fold(
      (failure) {
        AppLogger.warning('loadMatchHistory failed: ${failure.message}', tag: 'Profile');
        state = state.copyWith(viewState: MatchHistoryViewState.error, errorMessage: failure.message);
      },
      (data) {
        state = state.copyWith(
          viewState: MatchHistoryViewState.loaded,
          entries: data.entries,
          page: data.page,
          totalPages: data.totalPages,
          clearError: true,
        );
      },
    );
  }
}
