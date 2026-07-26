import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/competition_repository.dart';

class GetCompetitionsParams extends Equatable {
  final int page;
  final int limit;
  final String? search;

  const GetCompetitionsParams({
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
    this.search,
  });

  @override
  List<Object?> get props => [page, limit, search];
}

class GetCompetitions implements UseCase<CompetitionListResult, GetCompetitionsParams> {
  final CompetitionRepository repository;

  GetCompetitions(this.repository);

  @override
  Future<Either<Failure, CompetitionListResult>> call(GetCompetitionsParams params) {
    return repository.getCompetitions(
      page: params.page,
      limit: params.limit,
      search: params.search,
    );
  }
}
