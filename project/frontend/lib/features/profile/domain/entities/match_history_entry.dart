import 'package:equatable/equatable.dart';

/// How one settled match turned out for the player, from their own point
/// of view — mirrors `MatchResult`'s scores but pre-reduced to a single
/// tag so `MatchHistoryPage` can render a W/L/D chip without comparing
/// scores itself on every list item.
enum MatchOutcome { win, loss, draw }

/// The opponent's identity as it comes back with a history row — same
/// shape as `MatchResultPlayer`/`LeaderboardPlayer`, but this is the
/// domain source of truth for who was faced in *this* settled match.
class MatchHistoryOpponent extends Equatable {
  final String name;
  final String? photoUrl;

  const MatchHistoryOpponent({required this.name, this.photoUrl});

  @override
  List<Object?> get props => [name, photoUrl];
}

/// One row from `ApiConstants.profileMatchHistory`. Backs
/// `MatchHistoryPage`'s list — a paged feed of the player's own settled
/// matches, most recent first, distinct from `MatchResult` (the full
/// per-match breakdown fetched right after *that* match ends).
class MatchHistoryEntry extends Equatable {
  final String matchId;
  final MatchHistoryOpponent opponent;
  final String category;
  final MatchOutcome outcome;
  final int yourScore;
  final int opponentScore;
  final int correctAnswers;
  final int totalQuestions;
  final int pointsEarned;
  final DateTime playedAt;

  const MatchHistoryEntry({
    required this.matchId,
    required this.opponent,
    required this.category,
    required this.outcome,
    required this.yourScore,
    required this.opponentScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.pointsEarned,
    required this.playedAt,
  });

  @override
  List<Object?> get props => [
        matchId,
        opponent,
        category,
        outcome,
        yourScore,
        opponentScore,
        correctAnswers,
        totalQuestions,
        pointsEarned,
        playedAt,
      ];
}
