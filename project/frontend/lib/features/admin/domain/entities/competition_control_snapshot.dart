import 'package:equatable/equatable.dart';

/// Lifecycle of the competition as controlled from the admin dashboard.
///
/// Deliberately smaller than any backend `CompetitionStatus` enum might
/// be (e.g. no `scheduled`/`archived`) — this is only the three states
/// the *control panel itself* cares about switching between. Map the
/// backend's real enum onto this one in the data layer (TODO(backend)
/// in `CompetitionControlNotifier.loadDashboard`) rather than widening
/// this to match it 1:1.
enum CompetitionControlStatus { running, paused, ended }

/// One player as shown in a match card — deliberately minimal (no full
/// `Player`/`Account` entity) since the dashboard only ever needs a name
/// and a live score for this, not a profile.
class ControlMatchPlayer extends Equatable {
  final String id;
  final String name;
  final int score;

  const ControlMatchPlayer({
    required this.id,
    required this.name,
    this.score = 0,
  });

  @override
  List<Object?> get props => [id, name, score];
}

/// The match currently in progress, if any. `startedAt` (rather than a
/// pre-computed "elapsed seconds") is what the server should push, so
/// the on-screen timer stays correct across a UI reconnect/rebuild
/// without needing a fresh tick from the backend every second.
class CurrentMatch extends Equatable {
  final String matchId;
  final ControlMatchPlayer playerA;
  final ControlMatchPlayer playerB;
  final DateTime startedAt;

  /// Target match length, if the game mode has a fixed duration (e.g. a
  /// timed quiz round). Null for modes that just run until both players
  /// finish (e.g. Aviator-style) — the UI falls back to a plain
  /// count-up timer when this is null instead of a countdown ring.
  final int? durationSeconds;

  const CurrentMatch({
    required this.matchId,
    required this.playerA,
    required this.playerB,
    required this.startedAt,
    this.durationSeconds,
  });

  @override
  List<Object?> get props => [matchId, playerA, playerB, startedAt, durationSeconds];
}

/// Preview of whoever's queued up next. Both players are null while the
/// matchmaker is still filling the next pair — the card shows a
/// "waiting for players" placeholder in that case rather than treating
/// it as an error state.
class NextMatchPreview extends Equatable {
  final ControlMatchPlayer? playerA;
  final ControlMatchPlayer? playerB;
  final int? estimatedStartInSeconds;

  const NextMatchPreview({
    this.playerA,
    this.playerB,
    this.estimatedStartInSeconds,
  });

  bool get isReady => playerA != null && playerB != null;

  @override
  List<Object?> get props => [playerA, playerB, estimatedStartInSeconds];
}

/// The four headline counters in the "Live Statistics" section.
class LiveStats extends Equatable {
  final int totalPlayers;
  final int matchesCompleted;
  final int matchesRunning;
  final int playersWaiting;

  const LiveStats({
    this.totalPlayers = 0,
    this.matchesCompleted = 0,
    this.matchesRunning = 0,
    this.playersWaiting = 0,
  });

  @override
  List<Object?> get props => [totalPlayers, matchesCompleted, matchesRunning, playersWaiting];
}

/// The three alert categories the dashboard surfaces. Kept as a closed
/// enum (rather than a free-text "type" string from the backend) so the
/// UI can exhaustively switch on it for icon/color/copy — widen this
/// enum first if the backend ever adds a fourth alert category.
enum DashboardAlertType { paymentFailed, disconnectedPlayer, playerReport }

class DashboardAlert extends Equatable {
  final String id;
  final DashboardAlertType type;
  final String message;
  final DateTime occurredAt;

  const DashboardAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.occurredAt,
  });

  @override
  List<Object?> get props => [id, type, message, occurredAt];
}
