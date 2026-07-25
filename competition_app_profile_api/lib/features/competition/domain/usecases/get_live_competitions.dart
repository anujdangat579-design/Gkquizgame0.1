import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/live_competition.dart';
import '../repositories/live_competition_repository.dart';

class GetLiveCompetitionsParams extends Equatable {
  final String? category;

  const GetLiveCompetitionsParams({this.category});

  @override
  List<Object?> get props => [category];
}

class GetLiveCompetitions implements UseCase<List<LiveCompetition>, GetLiveCompetitionsParams> {
  final LiveCompetitionRepository repository;

  GetLiveCompetitions(this.repository);

  @override
  Future<Either<Failure, List<LiveCompetition>>> call(GetLiveCompetitionsParams params) {
    return repository.getLiveCompetitions(category: params.category);
  }
}
