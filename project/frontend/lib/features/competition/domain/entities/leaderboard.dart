import 'package:equatable/equatable.dart';

/// Selectable leaderboard window — mirrors `LeaderboardPage`'s
/// `_LeaderboardRange` (its UI-only twin), but this is the domain source
/// of truth passed down to `ApiConstants.leaderboard`'s `range` query
/// param via [apiValue].
enum LeaderboardRange { today, weekly, allTime }

extension LeaderboardRangeApiValue on LeaderboardRange {
  String get apiValue {
    switch (this) {
      case LeaderboardRange.today:
        return 'today';
      case LeaderboardRange.weekly:
        return 'weekly';
      case LeaderboardRange.allTime:
        return 'all_time';
    }
  }
}

/// A ranked player's identity, as it comes back with a leaderboard
/// entry — same shape as `MatchResultPlayer`/`QueuePlayer`, but this is
/// the domain source of truth for a leaderboard row rather than a match
/// outcome or matchmaking pairing.
class LeaderboardPlayer extends Equatable {
  final String name;
  final String? photoUrl;
  final String rankLabel;

  const LeaderboardPlayer({
    required this.name,
    this.photoUrl,
    this.rankLabel = 'Unranked',
  });

  @override
  List<Object?> get props => [name, photoUrl, rankLabel];
}

/// One ranked row from `ApiConstants.leaderboard`. Mirrors
/// `LeaderboardPage`'s local-only `LeaderboardEntry`, but sourced from
/// the backend instead of a fixed local list.
class LeaderboardRankEntry extends Equatable {
  final int rank;
  final LeaderboardPlayer player;
  final int points;
  final bool isCurrentUser;

  const LeaderboardRankEntry({
    required this.rank,
    required this.player,
    required this.points,
    this.isCurrentUser = false,
  });

  @override
  List<Object?> get props => [rank, player, points, isCurrentUser];
}

/// The settled leaderboard for one [LeaderboardRange], from
/// `ApiConstants.leaderboard`. Backs `LeaderboardPage`'s podium + ranked
/// list, previously fixed local data (see that page's old doc comment).
class LeaderboardBoard extends Equatable {
  /// Top-ranked entries the backend sends back for this range —
  /// typically top N (e.g. top 100), not the whole player base.
  final List<LeaderboardRankEntry> entries;

  /// The requesting player's own entry, sent separately by the backend
  /// when they aren't already inside [entries] (e.g. ranked below the
  /// top N) — mirrors `LeaderboardPage`'s pinned "You" row shown below
  /// the divider when `currentUserVisible` is false. Null when the
  /// backend doesn't send one at all (e.g. the player is inside
  /// [entries] already, or has no rank yet).
  final LeaderboardRankEntry? currentUserEntry;

  const LeaderboardBoard({required this.entries, this.currentUserEntry});

  @override
  List<Object?> get props => [entries, currentUserEntry];
}
