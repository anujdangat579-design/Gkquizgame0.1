import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_question.dart';
import '../repositories/question_repository.dart';

class UpdateQuestionParams extends Equatable {
  final String id;
  final String? categoryId;
  final String? text;
  final List<String>? options;
  final int? correctOptionIndex;
  final QuestionDifficulty? difficulty;

  const UpdateQuestionParams({
    required this.id,
    this.categoryId,
    this.text,
    this.options,
    this.correctOptionIndex,
    this.difficulty,
  });

  @override
  List<Object?> get props => [id, categoryId, text, options, correctOptionIndex, difficulty];
}

class UpdateQuestion implements UseCase<AdminQuestion, UpdateQuestionParams> {
  final QuestionRepository repository;

  UpdateQuestion(this.repository);

  @override
  Future<Either<Failure, AdminQuestion>> call(UpdateQuestionParams params) {
    return repository.updateQuestion(
      id: params.id,
      categoryId: params.categoryId,
      text: params.text,
      options: params.options,
      correctOptionIndex: params.correctOptionIndex,
      difficulty: params.difficulty,
    );
  }
}
