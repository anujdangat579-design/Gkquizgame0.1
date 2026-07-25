import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/answer_result.dart';
import '../repositories/quiz_repository.dart';

class SubmitAnswerParams extends Equatable {
  final String queueId;
  final String questionId;
  final int? selectedOptionIndex;

  const SubmitAnswerParams({
    required this.queueId,
    required this.questionId,
    this.selectedOptionIndex,
  });

  @override
  List<Object?> get props => [queueId, questionId, selectedOptionIndex];
}

class SubmitAnswer implements UseCase<AnswerResult, SubmitAnswerParams> {
  final QuizRepository repository;

  SubmitAnswer(this.repository);

  @override
  Future<Either<Failure, AnswerResult>> call(SubmitAnswerParams params) {
    return repository.submitAnswer(
      queueId: params.queueId,
      questionId: params.questionId,
      selectedOptionIndex: params.selectedOptionIndex,
    );
  }
}
