import '../../domain/entities/leaderboard.dart';

class LeaderboardPlayerModel extends LeaderboardPlayer {
  const LeaderboardPlayerModel({
    required super.name,
    super.photoUrl,
    super.rankLabel,
  });

  /// Field names are a best guess, same unconfirmed-schema caveat as
  /// `MatchResultPlayerModel` — accepts `name`/`playerName`,
  /// `photoUrl`/`avatarUrl`, `rankLabel`/`rank`. Falls back to
  /// "Unranked" if the backend doesn't send a rank at all.
  factory LeaderboardPlayerModel.fromJson(Map<String, dynamic> json, {required String fallbackName}) {
    return LeaderboardPlayerModel(
      name: (json['name'] ?? json['playerName'] ?? fallbackName).toString(),
      photoUrl: (json['photoUrl'] ?? json['avatarUrl'])?.toString(),
      rankLabel: (json['rankLabel'] ?? json['rank'])?.toString() ?? 'Unranked',
    );
  }
}

class LeaderboardRankEntryModel extends LeaderboardRankEntry {
  const LeaderboardRankEntryModel({
    required super.rank,
    required super.player,
    required super.points,
    super.isCurrentUser,
  });

  /// Same unconfirmed-schema caveat as everything else here. `rank`
  /// falls back to the item's 1-based position in the list if the
  /// backend doesn't send one explicitly. `player` falls back to a bare
  /// name if the backend sends it as a plain string.
  factory LeaderboardRankEntryModel.fromJson(Map<String, dynamic> json, {required int fallbackRank}) {
    return LeaderboardRankEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? fallbackRank,
      player: _parsePlayer(json['player'] ?? json['user']),
      points: (json['points'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? json['isYou'] as bool? ?? false,
    );
  }

  static LeaderboardPlayerModel _parsePlayer(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return LeaderboardPlayerModel.fromJson(raw, fallbackName: 'Player');
    }
    if (raw is String) return LeaderboardPlayerModel(name: raw);
    return const LeaderboardPlayerModel(name: 'Player');
  }
}

class LeaderboardBoardModel extends LeaderboardBoard {
  const LeaderboardBoardModel({
    required super.entries,
    super.currentUserEntry,
  });

  /// Field names are a best guess — no confirmed schema yet for
  /// `ApiConstants.leaderboard` (see that constant's doc comment).
  /// `currentUserEntry` is left null (rather than synthesized) when the
  /// backend doesn't send one, so callers can tell "not sent" apart from
  /// "player genuinely has no rank yet".
  factory LeaderboardBoardModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] ?? json['leaderboard'] ?? json['rankings'];
    final entries = rawEntries is List<dynamic>
        ? [
            for (int i = 0; i < rawEntries.length; i++)
              LeaderboardRankEntryModel.fromJson(rawEntries[i] as Map<String, dynamic>, fallbackRank: i + 1),
          ]
        : <LeaderboardRankEntryModel>[];

    final rawCurrentUser = json['currentUserEntry'] ?? json['yourEntry'] ?? json['you'];

    return LeaderboardBoardModel(
      entries: entries,
      currentUserEntry: rawCurrentUser is Map<String, dynamic>
          ? LeaderboardRankEntryModel.fromJson(rawCurrentUser, fallbackRank: 0)
          : null,
    );
  }
}
