import 'package:equatable/equatable.dart';

/// Pure domain entity — a single aggregate snapshot for the admin
/// Dashboard's stat cards. No JSON, no Dio.
///
/// Replaces `DashboardPage`'s previous client-side approximation (see
/// that file's doc comment), which only ever counted whichever single
/// page of `GetCompetitions` happened to be loaded — correct for a
/// handful of competitions, silently wrong once results paginate. This
/// entity is the real, backend-computed aggregate instead.
class DashboardStatistics extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int totalCompetitions;
  final int activeCompetitions;
  final int totalQuestions;
  final int totalMatchesPlayed;
  final double totalRevenue;
  final int newUsersToday;
  final int matchesPlayedToday;

  const DashboardStatistics({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalCompetitions = 0,
    this.activeCompetitions = 0,
    this.totalQuestions = 0,
    this.totalMatchesPlayed = 0,
    this.totalRevenue = 0,
    this.newUsersToday = 0,
    this.matchesPlayedToday = 0,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        activeUsers,
        totalCompetitions,
        activeCompetitions,
        totalQuestions,
        totalMatchesPlayed,
        totalRevenue,
        newUsersToday,
        matchesPlayedToday,
      ];
}
