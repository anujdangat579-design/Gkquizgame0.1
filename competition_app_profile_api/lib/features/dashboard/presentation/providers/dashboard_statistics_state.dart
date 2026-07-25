import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_statistics.dart';

enum DashboardViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `CompetitionState`'s shape/conventions.
class DashboardStatisticsState extends Equatable {
  final DashboardViewState viewState;
  final DashboardStatistics statistics;
  final String? errorMessage;

  const DashboardStatisticsState({
    this.viewState = DashboardViewState.initial,
    this.statistics = const DashboardStatistics(),
    this.errorMessage,
  });

  DashboardStatisticsState copyWith({
    DashboardViewState? viewState,
    DashboardStatistics? statistics,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardStatisticsState(
      viewState: viewState ?? this.viewState,
      statistics: statistics ?? this.statistics,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, statistics, errorMessage];
}
