import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/leaderboard.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (LeaderboardRepositoryImpl); the
/// presentation layer never talks to it directly, only through
/// `GetLeaderboard`.
abstract class LeaderboardRepository {
  Future<Either<Failure, LeaderboardBoard>> getLeaderboard({required LeaderboardRange range});
}
