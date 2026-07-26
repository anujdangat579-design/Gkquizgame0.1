import '../../domain/entities/player_statistics.dart';

class CategoryStatModel extends CategoryStat {
  const CategoryStatModel({
    required super.category,
    required super.matchesPlayed,
    required super.wins,
    required super.accuracy,
  });

  factory CategoryStatModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatModel(
      category: json['category']?.toString() ?? 'General',
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PlayerStatisticsModel extends PlayerStatistics {
  const PlayerStatisticsModel({
    required super.totalMatches,
    required super.wins,
    required super.losses,
    required super.draws,
    required super.winRate,
    required super.accuracy,
    required super.currentStreak,
    required super.bestStreak,
    required super.totalPointsEarned,
    super.categoryBreakdown,
  });

  factory PlayerStatisticsModel.fromJson(Map<String, dynamic> json) {
    final breakdown = json['categoryBreakdown'] as List<dynamic>?;
    return PlayerStatisticsModel(
      totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
      categoryBreakdown: breakdown
          ?.map((e) => CategoryStatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
