import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/competition.dart';
import '../repositories/competition_repository.dart';

class UpdateCompetitionParams extends Equatable {
  final String id;
  final String? name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  const UpdateCompetitionParams({
    required this.id,
    this.name,
    this.description,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [id, name, description, startDate, endDate];
}

class UpdateCompetition implements UseCase<Competition, UpdateCompetitionParams> {
  final CompetitionRepository repository;

  UpdateCompetition(this.repository);

  @override
  Future<Either<Failure, Competition>> call(UpdateCompetitionParams params) {
    final hasAnyField = params.name != null ||
        params.description != null ||
        params.startDate != null ||
        params.endDate != null;
    if (!hasAnyField) {
      return Future.value(const Left(ValidationFailure('At least one field must be provided')));
    }
    return repository.updateCompetition(
      id: params.id,
      name: params.name,
      description: params.description,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
