import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/competition_repository.dart';

class DeleteCompetition implements UseCase<void, String> {
  final CompetitionRepository repository;

  DeleteCompetition(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteCompetition(id);
  }
}
