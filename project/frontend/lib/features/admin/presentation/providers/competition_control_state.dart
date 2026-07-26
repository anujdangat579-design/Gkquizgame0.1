import 'package:equatable/equatable.dart';

import '../../domain/entities/competition_control_snapshot.dart';

enum CompetitionControlViewState { initial, loading, loaded, error }

/// Identifies which control button (if any) currently has a mutating
/// request in flight, so `CompetitionControlActions` can show a spinner
/// on *that one* button instead of a global full-page loading state —
/// the admin should still be able to see the live match/stats update
/// underneath while e.g. "End competition" is being confirmed.
enum CompetitionControlAction { start, pauseMatchmaking, resumeMatchmaking, end }

/// Full state Riverpod's StateNotifier emits for one competition's
/// control dashboard. Mirrors `LiveCompetitionState`'s shape (a single
/// `viewState` plus the data), extended with the realtime-connection
/// and in-flight-action fields this screen additionally needs.
class CompetitionControlState extends Equatable {
  final CompetitionControlViewState viewState;

  final String competitionName;
  final CompetitionControlStatus status;
  final int playersWaiting;
  final CurrentMatch? currentMatch;
  final NextMatchPreview? nextMatch;
  final LiveStats stats;
  final List<DashboardAlert> alerts;

  /// Whether the Socket.IO connection backing auto-refresh is currently
  /// up. Surfaced in the app bar so an admin doesn't mistake a dropped
  /// socket for "nothing is happening right now".
  final bool isLiveConnected;

  final CompetitionControlAction? pendingAction;
  final String? errorMessage;

  const CompetitionControlState({
    this.viewState = CompetitionControlViewState.initial,
    this.competitionName = '',
    this.status = CompetitionControlStatus.ended,
    this.playersWaiting = 0,
    this.currentMatch,
    this.nextMatch,
    this.stats = const LiveStats(),
    this.alerts = const [],
    this.isLiveConnected = false,
    this.pendingAction,
    this.errorMessage,
  });

  CompetitionControlState copyWith({
    CompetitionControlViewState? viewState,
    String? competitionName,
    CompetitionControlStatus? status,
    int? playersWaiting,
    CurrentMatch? currentMatch,
    bool clearCurrentMatch = false,
    NextMatchPreview? nextMatch,
    LiveStats? stats,
    List<DashboardAlert>? alerts,
    bool? isLiveConnected,
    CompetitionControlAction? pendingAction,
    bool clearPendingAction = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CompetitionControlState(
      viewState: viewState ?? this.viewState,
      competitionName: competitionName ?? this.competitionName,
      status: status ?? this.status,
      playersWaiting: playersWaiting ?? this.playersWaiting,
      currentMatch: clearCurrentMatch ? null : (currentMatch ?? this.currentMatch),
      nextMatch: nextMatch ?? this.nextMatch,
      stats: stats ?? this.stats,
      alerts: alerts ?? this.alerts,
      isLiveConnected: isLiveConnected ?? this.isLiveConnected,
      pendingAction: clearPendingAction ? null : (pendingAction ?? this.pendingAction),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        viewState,
        competitionName,
        status,
        playersWaiting,
        currentMatch,
        nextMatch,
        stats,
        alerts,
        isLiveConnected,
        pendingAction,
        errorMessage,
      ];
}
