import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_result.dart';
import '../repositories/quiz_repository.dart';

class GetMatchResultParams extends Equatable {
  final String queueId;

  const GetMatchResultParams({required this.queueId});

  @override
  List<Object?> get props => [queueId];
}

class GetMatchResult implements UseCase<MatchResult, GetMatchResultParams> {
  final QuizRepository repository;

  GetMatchResult(this.repository);

  @override
  Future<Either<Failure, MatchResult>> call(GetMatchResultParams params) {
    return repository.getMatchResult(queueId: params.queueId);
  }
}
