import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/answer_result_model.dart';
import '../models/match_result_model.dart';
import '../models/question_model.dart';

/// Talks directly to `ApiConstants.matchQuestions` / `submitAnswer` (see
/// those constants' doc comments for why the paths are best guesses).
/// Throws [ServerException]/[NetworkException]/etc. (via [DioClient]),
/// which the repository catches and converts to Failures — same shape
/// as [LiveCompetitionRemoteDataSource].
abstract class QuizRemoteDataSource {
  Future<QuizQuestionSetModel> getQuestions({required String queueId});

  Future<AnswerResultModel> submitAnswer({
    required String queueId,
    required String questionId,
    int? selectedOptionIndex,
  });

  Future<MatchResultModel> getMatchResult({required String queueId});
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final DioClient client;

  QuizRemoteDataSourceImpl(this.client);

  @override
  Future<QuizQuestionSetModel> getQuestions({required String queueId}) async {
    final response = await client.get(ApiConstants.matchQuestions(queueId));
    return QuizQuestionSetModel.fromJson(response.data);
  }

  @override
  Future<AnswerResultModel> submitAnswer({
    required String queueId,
    required String questionId,
    int? selectedOptionIndex,
  }) async {
    final response = await client.post(
      ApiConstants.submitAnswer(queueId),
      data: {
        'questionId': questionId,
        'selectedOptionIndex': selectedOptionIndex,
      },
    );
    return AnswerResultModel.fromJson(
      response.data as Map<String, dynamic>,
      requestedQuestionId: questionId,
    );
  }

  @override
  Future<MatchResultModel> getMatchResult({required String queueId}) async {
    final response = await client.get(ApiConstants.matchResult(queueId));
    return MatchResultModel.fromJson(response.data as Map<String, dynamic>);
  }
}
