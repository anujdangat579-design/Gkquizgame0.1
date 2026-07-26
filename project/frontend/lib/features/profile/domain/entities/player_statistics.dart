import 'package:equatable/equatable.dart';

/// One category's slice of the player's overall stats — optional
/// per-category breakdown alongside the aggregate totals in
/// [PlayerStatistics], same "may not be sent" caveat as
/// `MatchResult.questionBreakdown`.
class CategoryStat extends Equatable {
  final String category;
  final int matchesPlayed;
  final int wins;
  final double accuracy;

  const CategoryStat({
    required this.category,
    required this.matchesPlayed,
    required this.wins,
    required this.accuracy,
  });

  @override
  List<Object?> get props => [category, matchesPlayed, wins, accuracy];
}

/// The player's settled aggregate stats, from
/// `ApiConstants.profileStatistics`. Backs `StatisticsPage`'s summary
/// cards — a single snapshot computed server-side across the player's
/// *entire* history, not something the client derives from whatever page
/// of `ApiConstants.profileMatchHistory` happens to be loaded.
class PlayerStatistics extends Equatable {
  final int totalMatches;
  final int wins;
  final int losses;
  final int draws;

  /// 0.0–1.0, i.e. `wins / totalMatches` — sent by the backend rather
  /// than computed client-side so rounding/edge cases (0 matches played)
  /// are handled consistently in one place.
  final double winRate;

  /// 0.0–1.0 across every answered question in the player's history,
  /// not just the currently-loaded match history page.
  final double accuracy;

  final int currentStreak;
  final int bestStreak;
  final int totalPointsEarned;

  /// Null when the backend doesn't send a per-category split — callers
  /// fall back to showing just the aggregate totals above.
  final List<CategoryStat>? categoryBreakdown;

  const PlayerStatistics({
    required this.totalMatches,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.accuracy,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalPointsEarned,
    this.categoryBreakdown,
  });

  @override
  List<Object?> get props => [
        totalMatches,
        wins,
        losses,
        draws,
        winRate,
        accuracy,
        currentStreak,
        bestStreak,
        totalPointsEarned,
        categoryBreakdown,
      ];
}
