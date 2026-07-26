import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/admin_question.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/question_remote_data_source.dart';

/// Concrete implementation the DI container binds to
/// [QuestionRepository]. Checks connectivity, calls the remote data
/// source, and converts any thrown exception into a typed [Failure] via
/// Dartz's Either. Mirrors `CompetitionRepositoryImpl`'s shape.
class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QuestionRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, QuestionListResult>> getQuestions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? categoryId,
    QuestionDifficulty? difficulty,
    String? search,
  }) {
    return _guard(() async {
      final page_ = await remoteDataSource.getQuestions(
        page: page,
        limit: limit,
        categoryId: categoryId,
        difficulty: difficulty,
        search: search,
      );
      return QuestionListResult(
        questions: page_.questions,
        page: page_.page,
        limit: page_.limit,
        total: page_.total,
        totalPages: page_.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, AdminQuestion>> getQuestionById(String id) {
    return _guard(() => remoteDataSource.getQuestionById(id));
  }

  @override
  Future<Either<Failure, AdminQuestion>> createQuestion({
    required String categoryId,
    required String text,
    required List<String> options,
    required int correctOptionIndex,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) {
    return _guard(() => remoteDataSource.createQuestion(
          categoryId: categoryId,
          text: text,
          options: options,
          correctOptionIndex: correctOptionIndex,
          difficulty: difficulty,
        ));
  }

  @override
  Future<Either<Failure, AdminQuestion>> updateQuestion({
    required String id,
    String? categoryId,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
    QuestionDifficulty? difficulty,
  }) {
    return _guard(() => remoteDataSource.updateQuestion(
          id: id,
          categoryId: categoryId,
          text: text,
          options: options,
          correctOptionIndex: correctOptionIndex,
          difficulty: difficulty,
        ));
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(String id) {
    return _guard(() => remoteDataSource.deleteQuestion(id));
  }

  /// Shared "check connectivity, run the call, map exceptions" wrapper —
  /// identical to `CompetitionRepositoryImpl._guard`.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await action();
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
