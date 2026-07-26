import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/quiz_question_set.dart';
import '../repositories/quiz_repository.dart';

class GetQuizQuestionsParams extends Equatable {
  final String queueId;

  const GetQuizQuestionsParams({required this.queueId});

  @override
  List<Object?> get props => [queueId];
}

class GetQuizQuestions implements UseCase<QuizQuestionSet, GetQuizQuestionsParams> {
  final QuizRepository repository;

  GetQuizQuestions(this.repository);

  @override
  Future<Either<Failure, QuizQuestionSet>> call(GetQuizQuestionsParams params) {
    return repository.getQuestions(queueId: params.queueId);
  }
}
