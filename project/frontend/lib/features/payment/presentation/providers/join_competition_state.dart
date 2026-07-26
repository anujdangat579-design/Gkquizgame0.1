import 'package:equatable/equatable.dart';

import '../../../matchmaking/domain/entities/matchmaking_entry.dart';

enum JoinCompetitionViewState {
  idle,
  creatingOrder,
  awaitingCheckout,
  verifying,
  enteringQueue,
  joined,
  error,
}

/// Immutable state Riverpod's StateNotifier emits for one competition's
/// join-and-pay flow. Mirrors `CompetitionDetailsState`'s shape.
///
/// `matchmakingEntry` is only ever non-null once `viewState` reaches
/// `joined` — it's the result of `EnterMatchmakingQueue`, called right
/// after the backend confirms the payment and entry (see
/// `JoinCompetitionNotifier.join`), and carries the real queue position
/// / players-ahead / wait-time `CompetitionDetailsPage` hands off to
/// `WaitingQueuePage`.
class JoinCompetitionState extends Equatable {
  final JoinCompetitionViewState viewState;
  final String? errorMessage;
  final MatchmakingEntry? matchmakingEntry;

  const JoinCompetitionState({
    this.viewState = JoinCompetitionViewState.idle,
    this.errorMessage,
    this.matchmakingEntry,
  });

  bool get isInProgress => viewState == JoinCompetitionViewState.creatingOrder ||
      viewState == JoinCompetitionViewState.awaitingCheckout ||
      viewState == JoinCompetitionViewState.verifying ||
      viewState == JoinCompetitionViewState.enteringQueue;

  JoinCompetitionState copyWith({
    JoinCompetitionViewState? viewState,
    String? errorMessage,
    MatchmakingEntry? matchmakingEntry,
    bool clearError = false,
  }) {
    return JoinCompetitionState(
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      matchmakingEntry: matchmakingEntry ?? this.matchmakingEntry,
    );
  }

  @override
  List<Object?> get props => [viewState, errorMessage, matchmakingEntry];
}
