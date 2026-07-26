import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_live_competitions.dart';
import 'live_competition_state.dart';

/// `ref.watch(liveCompetitionNotifierProvider)` gives the current
/// [LiveCompetitionState]; `ref.read(...notifier)` gives access to
/// [loadLiveCompetitions]. Use case comes from get_it (`sl`) — same
/// split as `categoryNotifierProvider`.
final liveCompetitionNotifierProvider =
    StateNotifierProvider<LiveCompetitionNotifier, LiveCompetitionState>((ref) {
  return LiveCompetitionNotifier(getLiveCompetitions: sl());
});

class LiveCompetitionNotifier extends StateNotifier<LiveCompetitionState> {
  final GetLiveCompetitions getLiveCompetitions;

  LiveCompetitionNotifier({required this.getLiveCompetitions}) : super(const LiveCompetitionState());

  Future<void> loadLiveCompetitions({String? category}) async {
    state = state.copyWith(viewState: LiveCompetitionViewState.loading, clearError: true);

    final result = await getLiveCompetitions(GetLiveCompetitionsParams(category: category));

    result.fold(
      (failure) {
        AppLogger.warning('loadLiveCompetitions failed: ${failure.message}', tag: 'LiveCompetition');
        state = state.copyWith(viewState: LiveCompetitionViewState.error, errorMessage: failure.message);
      },
      (liveCompetitions) {
        state = state.copyWith(
          viewState: LiveCompetitionViewState.loaded,
          liveCompetitions: liveCompetitions,
          clearError: true,
        );
      },
    );
  }
}
