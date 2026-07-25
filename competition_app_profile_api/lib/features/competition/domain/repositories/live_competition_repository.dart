import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/live_competition.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (LiveCompetitionRepositoryImpl); the
/// presentation layer never talks to it directly, only through use
/// cases. Mirrors CategoryRepository's shape — a single unpaginated
/// list, since "live" competitions are expected to be a short,
/// currently-open set rather than something a player pages through.
abstract class LiveCompetitionRepository {
  Future<Either<Failure, List<LiveCompetition>>> getLiveCompetitions({String? category});
}
