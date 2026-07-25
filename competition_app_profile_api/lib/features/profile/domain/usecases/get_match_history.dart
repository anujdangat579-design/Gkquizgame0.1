import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class GetMatchHistoryParams extends Equatable {
  final int page;
  final int limit;

  const GetMatchHistoryParams({
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
  });

  @override
  List<Object?> get props => [page, limit];
}

class GetMatchHistory implements UseCase<MatchHistoryResult, GetMatchHistoryParams> {
  final ProfileRepository repository;

  GetMatchHistory(this.repository);

  @override
  Future<Either<Failure, MatchHistoryResult>> call(GetMatchHistoryParams params) {
    return repository.getMatchHistory(page: params.page, limit: params.limit);
  }
}
