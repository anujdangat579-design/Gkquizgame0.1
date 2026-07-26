import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/competition.dart';
import '../repositories/competition_repository.dart';

class CreateCompetitionParams extends Equatable {
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateCompetitionParams({
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [name, description, startDate, endDate];
}

class CreateCompetition implements UseCase<Competition, CreateCompetitionParams> {
  final CompetitionRepository repository;

  CreateCompetition(this.repository);

  @override
  Future<Either<Failure, Competition>> call(CreateCompetitionParams params) {
    if (params.name.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Name is required')));
    }
    return repository.createCompetition(
      name: params.name.trim(),
      description: params.description,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
