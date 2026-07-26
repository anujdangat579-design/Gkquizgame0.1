import 'package:equatable/equatable.dart';

import '../../domain/entities/player_statistics.dart';

enum StatisticsViewState { initial, loading, loaded, error }

/// Mirrors `LeaderboardState`'s shape — a single loaded snapshot,
/// reloaded from scratch rather than paged.
class StatisticsState extends Equatable {
  final StatisticsViewState viewState;
  final PlayerStatistics? statistics;
  final String? errorMessage;

  const StatisticsState({
    this.viewState = StatisticsViewState.initial,
    this.statistics,
    this.errorMessage,
  });

  StatisticsState copyWith({
    StatisticsViewState? viewState,
    PlayerStatistics? statistics,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsState(
      viewState: viewState ?? this.viewState,
      statistics: statistics ?? this.statistics,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, statistics, errorMessage];
}
