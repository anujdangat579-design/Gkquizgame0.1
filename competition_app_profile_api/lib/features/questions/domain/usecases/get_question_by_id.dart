import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_question.dart';
import '../repositories/question_repository.dart';

class GetQuestionById implements UseCase<AdminQuestion, String> {
  final QuestionRepository repository;

  GetQuestionById(this.repository);

  @override
  Future<Either<Failure, AdminQuestion>> call(String id) {
    return repository.getQuestionById(id);
  }
}
