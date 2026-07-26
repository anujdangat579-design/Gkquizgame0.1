import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/competition_details.dart';
import '../repositories/competition_details_repository.dart';

/// Takes the competition id directly as `Params` (no wrapper class
/// needed) — same shape as `DeleteCompetition`.
class GetCompetitionDetails implements UseCase<CompetitionDetails, String> {
  final CompetitionDetailsRepository repository;

  GetCompetitionDetails(this.repository);

  @override
  Future<Either<Failure, CompetitionDetails>> call(String id) {
    return repository.getCompetitionDetails(id);
  }
}
