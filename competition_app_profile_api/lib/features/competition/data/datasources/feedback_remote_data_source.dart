import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/feedback_result_model.dart';

/// Talks directly to `ApiConstants.matchFeedback(matchId)` (see that
/// method's doc comment for the endpoint-path caveat). Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures — same shape as
/// [QuizRemoteDataSource].
abstract class FeedbackRemoteDataSource {
  Future<FeedbackResultModel> submitFeedback({
    required String matchId,
    required int rating,
    String? comment,
    required bool reportedOpponent,
    String? reportReason,
  });
}

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  final DioClient client;

  FeedbackRemoteDataSourceImpl(this.client);

  @override
  Future<FeedbackResultModel> submitFeedback({
    required String matchId,
    required int rating,
    String? comment,
    required bool reportedOpponent,
    String? reportReason,
  }) async {
    final response = await client.post(
      ApiConstants.matchFeedback(matchId),
      data: {
        'rating': rating,
        'comment': comment,
        'reportedOpponent': reportedOpponent,
        'reportReason': reportedOpponent ? reportReason : null,
      },
    );

    // A 2xx with an empty/non-map body (e.g. 204 No Content) still
    // means the submission landed — see FeedbackResultModel.fromJson's
    // doc comment on why `submitted` defaults to true.
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return FeedbackResultModel.fromJson(data);
    }
    return const FeedbackResultModel(submitted: true);
  }
}
