import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/question_repository.dart';

class DeleteQuestion implements UseCase<void, String> {
  final QuestionRepository repository;

  DeleteQuestion(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteQuestion(id);
  }
}
