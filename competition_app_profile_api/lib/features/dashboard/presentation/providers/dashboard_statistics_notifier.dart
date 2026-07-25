import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_dashboard_statistics.dart';
import 'dashboard_statistics_state.dart';

/// The widget-facing provider. `ref.watch(dashboardStatisticsNotifierProvider)`
/// gives the current [DashboardStatisticsState]; `ref.read(...notifier)`
/// gives access to `load()` to trigger a (re)fetch. Mirrors
/// `competitionNotifierProvider`'s shape/conventions.
final dashboardStatisticsNotifierProvider =
    StateNotifierProvider<DashboardStatisticsNotifier, DashboardStatisticsState>((ref) {
  return DashboardStatisticsNotifier(getDashboardStatistics: sl());
});

class DashboardStatisticsNotifier extends StateNotifier<DashboardStatisticsState> {
  final GetDashboardStatistics getDashboardStatistics;

  DashboardStatisticsNotifier({required this.getDashboardStatistics})
      : super(const DashboardStatisticsState());

  Future<void> load() async {
    state = state.copyWith(viewState: DashboardViewState.loading);

    final result = await getDashboardStatistics(const NoParams());

    result.fold(
      (failure) {
        AppLogger.warning('loadDashboardStatistics failed: ${failure.message}', tag: 'Dashboard');
        state = state.copyWith(viewState: DashboardViewState.error, errorMessage: failure.message);
      },
      (data) {
        state = state.copyWith(
          viewState: DashboardViewState.loaded,
          statistics: data,
          clearError: true,
        );
      },
    );
  }
}
