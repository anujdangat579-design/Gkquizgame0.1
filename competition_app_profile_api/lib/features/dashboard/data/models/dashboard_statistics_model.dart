import '../../domain/entities/dashboard_statistics.dart';

/// Data-layer model. Knows how to deserialize JSON; the domain layer
/// never sees this class, only the [DashboardStatistics] entity it
/// extends. Field names are a best guess — same unconfirmed-schema
/// caveat as every other endpoint outside the confirmed `competitions`
/// CRUD scope (see `ApiConstants.dashboardStatistics`) — so this reads
/// defensively (multiple possible key spellings, defaulting to 0/0.0
/// rather than throwing) and should be tightened once the real backend
/// response shape is known.
class DashboardStatisticsModel extends DashboardStatistics {
  const DashboardStatisticsModel({
    super.totalUsers,
    super.activeUsers,
    super.totalCompetitions,
    super.activeCompetitions,
    super.totalQuestions,
    super.totalMatchesPlayed,
    super.totalRevenue,
    super.newUsersToday,
    super.matchesPlayedToday,
  });

  factory DashboardStatisticsModel.fromJson(Map<String, dynamic> json) {
    int intOf(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toInt();
      }
      return 0;
    }

    double doubleOf(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toDouble();
      }
      return 0;
    }

    return DashboardStatisticsModel(
      totalUsers: intOf(['totalUsers', 'total_users']),
      activeUsers: intOf(['activeUsers', 'active_users']),
      totalCompetitions: intOf(['totalCompetitions', 'total_competitions']),
      activeCompetitions: intOf(['activeCompetitions', 'active_competitions']),
      totalQuestions: intOf(['totalQuestions', 'total_questions']),
      totalMatchesPlayed: intOf(['totalMatchesPlayed', 'total_matches_played']),
      totalRevenue: doubleOf(['totalRevenue', 'total_revenue']),
      newUsersToday: intOf(['newUsersToday', 'new_users_today']),
      matchesPlayedToday: intOf(['matchesPlayedToday', 'matches_played_today']),
    );
  }
}
