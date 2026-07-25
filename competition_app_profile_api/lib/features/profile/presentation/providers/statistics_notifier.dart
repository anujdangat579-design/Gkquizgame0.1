import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_player_statistics.dart';
import 'statistics_state.dart';

final statisticsNotifierProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier(getPlayerStatistics: sl());
});

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final GetPlayerStatistics getPlayerStatistics;

  StatisticsNotifier({required this.getPlayerStatistics}) : super(const StatisticsState());

  Future<void> loadStatistics() async {
    state = state.copyWith(viewState: StatisticsViewState.loading, clearError: true);

    final result = await getPlayerStatistics(const NoParams());

    result.fold(
      (failure) {
        AppLogger.warning('loadStatistics failed: ${failure.message}', tag: 'Profile');
        state = state.copyWith(viewState: StatisticsViewState.error, errorMessage: failure.message);
      },
      (statistics) {
        state = state.copyWith(
          viewState: StatisticsViewState.loaded,
          statistics: statistics,
          clearError: true,
        );
      },
    );
  }
}
