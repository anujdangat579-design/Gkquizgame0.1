import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/competition.dart';

class CompetitionListResult {
  final List<Competition> competitions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const CompetitionListResult({
    required this.competitions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (CompetitionRepositoryImpl); the presentation
/// layer never talks to it directly, only through use cases.
abstract class CompetitionRepository {
  Future<Either<Failure, CompetitionListResult>> getCompetitions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? search,
  });

  Future<Either<Failure, Competition>> getCompetitionById(String id);

  Future<Either<Failure, Competition>> createCompetition({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, Competition>> updateCompetition({
    required String id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, Competition>> setCompetitionStatus({
    required String id,
    required bool enabled,
  });

  Future<Either<Failure, void>> deleteCompetition(String id);
}
