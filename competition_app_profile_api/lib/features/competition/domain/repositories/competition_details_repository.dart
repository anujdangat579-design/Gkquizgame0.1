import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/competition_details.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (CompetitionDetailsRepositoryImpl); the
/// presentation layer never talks to it directly, only through the
/// `GetCompetitionDetails` use case.
abstract class CompetitionDetailsRepository {
  Future<Either<Failure, CompetitionDetails>> getCompetitionDetails(String id);
}
