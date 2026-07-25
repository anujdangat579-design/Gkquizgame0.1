import 'package:equatable/equatable.dart';

import '../../domain/entities/leaderboard.dart';

enum LeaderboardViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `QuizState`'s shape — a single loaded snapshot for the currently
/// selected [range], reloaded from scratch whenever that changes rather
/// than accumulating/paging.
class LeaderboardState extends Equatable {
  final LeaderboardViewState viewState;
  final LeaderboardRange range;
  final LeaderboardBoard? board;
  final String? errorMessage;

  const LeaderboardState({
    this.viewState = LeaderboardViewState.initial,
    this.range = LeaderboardRange.weekly,
    this.board,
    this.errorMessage,
  });

  LeaderboardState copyWith({
    LeaderboardViewState? viewState,
    LeaderboardRange? range,
    LeaderboardBoard? board,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardState(
      viewState: viewState ?? this.viewState,
      range: range ?? this.range,
      board: board ?? this.board,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, range, board, errorMessage];
}
