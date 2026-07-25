import 'package:equatable/equatable.dart';

import '../../domain/entities/live_competition.dart';

enum LiveCompetitionViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `CategoryState`'s shape (a single unpaginated list, no mutations).
class LiveCompetitionState extends Equatable {
  final LiveCompetitionViewState viewState;
  final List<LiveCompetition> liveCompetitions;
  final String? errorMessage;

  const LiveCompetitionState({
    this.viewState = LiveCompetitionViewState.initial,
    this.liveCompetitions = const [],
    this.errorMessage,
  });

  LiveCompetitionState copyWith({
    LiveCompetitionViewState? viewState,
    List<LiveCompetition>? liveCompetitions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LiveCompetitionState(
      viewState: viewState ?? this.viewState,
      liveCompetitions: liveCompetitions ?? this.liveCompetitions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, liveCompetitions, errorMessage];
}
