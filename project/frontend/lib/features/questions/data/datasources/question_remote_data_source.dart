import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/admin_question.dart';
import '../models/admin_question_model.dart';

class QuestionPageModel {
  final List<AdminQuestionModel> questions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const QuestionPageModel({
    required this.questions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  /// Mirrors `CompetitionPageModel.fromJson`'s envelope shape:
  /// `{ questions: [...], pagination: { page, limit, total, totalPages } }`.
  factory QuestionPageModel.fromJson(Map<String, dynamic> json) {
    final list = AdminQuestionModel.listFromJson(json);
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return QuestionPageModel(
      questions: list,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? list.length,
      total: pagination['total'] as int? ?? list.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

/// Talks directly to `/api/admin/questions`. Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures. Mirrors
/// `CompetitionRemoteDataSource`'s shape/conventions.
abstract class QuestionRemoteDataSource {
  Future<QuestionPageModel> getQuestions({
    int page,
    int limit,
    String? categoryId,
    QuestionDifficulty? difficulty,
    String? search,
  });
  Future<AdminQuestionModel> getQuestionById(String id);
  Future<AdminQuestionModel> createQuestion({
    required String categoryId,
    required String text,
    required List<String> options,
    required int correctOptionIndex,
    required QuestionDifficulty difficulty,
  });
  Future<AdminQuestionModel> updateQuestion({
    required String id,
    String? categoryId,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
    QuestionDifficulty? difficulty,
  });
  Future<void> deleteQuestion(String id);
}

class QuestionRemoteDataSourceImpl implements QuestionRemoteDataSource {
  final DioClient client;

  QuestionRemoteDataSourceImpl(this.client);

  @override
  Future<QuestionPageModel> getQuestions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? categoryId,
    QuestionDifficulty? difficulty,
    String? search,
  }) async {
    final response = await client.get(
      ApiConstants.questions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (difficulty != null) 'difficulty': difficulty.name,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return QuestionPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminQuestionModel> getQuestionById(String id) async {
    final response = await client.get(ApiConstants.questionById(id));
    return AdminQuestionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminQuestionModel> createQuestion({
    required String categoryId,
    required String text,
    required List<String> options,
    required int correctOptionIndex,
    required QuestionDifficulty difficulty,
  }) async {
    final response = await client.post(
      ApiConstants.questions,
      data: AdminQuestionModel.toCreateJson(
        categoryId: categoryId,
        text: text,
        options: options,
        correctOptionIndex: correctOptionIndex,
        difficulty: difficulty,
      ),
    );
    return AdminQuestionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminQuestionModel> updateQuestion({
    required String id,
    String? categoryId,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
    QuestionDifficulty? difficulty,
  }) async {
    final response = await client.patch(
      ApiConstants.questionById(id),
      data: AdminQuestionModel.toUpdateJson(
        categoryId: categoryId,
        text: text,
        options: options,
        correctOptionIndex: correctOptionIndex,
        difficulty: difficulty,
      ),
    );
    return AdminQuestionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteQuestion(String id) async {
    await client.delete(ApiConstants.questionById(id));
  }
}
