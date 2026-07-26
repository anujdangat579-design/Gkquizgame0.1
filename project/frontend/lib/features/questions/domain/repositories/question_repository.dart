import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_question.dart';

class QuestionListResult {
  final List<AdminQuestion> questions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const QuestionListResult({
    required this.questions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (QuestionRepositoryImpl); the presentation
/// layer never talks to it directly, only through use cases. Mirrors
/// `CompetitionRepository`'s shape.
abstract class QuestionRepository {
  Future<Either<Failure, QuestionListResult>> getQuestions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? categoryId,
    QuestionDifficulty? difficulty,
    String? search,
  });

  Future<Either<Failure, AdminQuestion>> getQuestionById(String id);

  Future<Either<Failure, AdminQuestion>> createQuestion({
    required String categoryId,
    required String text,
    required List<String> options,
    required int correctOptionIndex,
    QuestionDifficulty difficulty,
  });

  Future<Either<Failure, AdminQuestion>> updateQuestion({
    required String id,
    String? categoryId,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
    QuestionDifficulty? difficulty,
  });

  Future<Either<Failure, void>> deleteQuestion(String id);
}
