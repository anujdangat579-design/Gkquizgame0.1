import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/competition.dart';
import '../repositories/competition_repository.dart';

class SetCompetitionStatusParams extends Equatable {
  final String id;
  final bool enabled;

  const SetCompetitionStatusParams({required this.id, required this.enabled});

  @override
  List<Object?> get props => [id, enabled];
}

class SetCompetitionStatus implements UseCase<Competition, SetCompetitionStatusParams> {
  final CompetitionRepository repository;

  SetCompetitionStatus(this.repository);

  @override
  Future<Either<Failure, Competition>> call(SetCompetitionStatusParams params) {
    return repository.setCompetitionStatus(id: params.id, enabled: params.enabled);
  }
}
