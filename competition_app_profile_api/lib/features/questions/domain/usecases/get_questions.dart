import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_question.dart';
import '../repositories/question_repository.dart';

class GetQuestionsParams extends Equatable {
  final int page;
  final int limit;
  final String? categoryId;
  final QuestionDifficulty? difficulty;
  final String? search;

  const GetQuestionsParams({
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
    this.categoryId,
    this.difficulty,
    this.search,
  });

  @override
  List<Object?> get props => [page, limit, categoryId, difficulty, search];
}

class GetQuestions implements UseCase<QuestionListResult, GetQuestionsParams> {
  final QuestionRepository repository;

  GetQuestions(this.repository);

  @override
  Future<Either<Failure, QuestionListResult>> call(GetQuestionsParams params) {
    return repository.getQuestions(
      page: params.page,
      limit: params.limit,
      categoryId: params.categoryId,
      difficulty: params.difficulty,
      search: params.search,
    );
  }
}
