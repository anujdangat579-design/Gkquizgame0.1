import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_question.dart';
import '../repositories/question_repository.dart';

class CreateQuestionParams extends Equatable {
  final String categoryId;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final QuestionDifficulty difficulty;

  const CreateQuestionParams({
    required this.categoryId,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    this.difficulty = QuestionDifficulty.medium,
  });

  @override
  List<Object?> get props => [categoryId, text, options, correctOptionIndex, difficulty];
}

class CreateQuestion implements UseCase<AdminQuestion, CreateQuestionParams> {
  final QuestionRepository repository;

  CreateQuestion(this.repository);

  @override
  Future<Either<Failure, AdminQuestion>> call(CreateQuestionParams params) {
    return repository.createQuestion(
      categoryId: params.categoryId,
      text: params.text,
      options: params.options,
      correctOptionIndex: params.correctOptionIndex,
      difficulty: params.difficulty,
    );
  }
}
