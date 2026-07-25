import '../../domain/entities/answer_result.dart';

class AnswerResultModel extends AnswerResult {
  const AnswerResultModel({
    required super.questionId,
    super.isCorrect,
    super.correctOptionIndex,
    super.yourScore,
    super.opponentScore,
  });

  /// Field names are a best guess (same unconfirmed-schema caveat as
  /// `QuestionModel` — no confirmed schema for this player-facing
  /// endpoint yet). `questionId` falls back to the id that was sent in
  /// the request if the backend doesn't echo it back, so callers always
  /// have something to key on.
  factory AnswerResultModel.fromJson(Map<String, dynamic> json, {required String requestedQuestionId}) {
    return AnswerResultModel(
      questionId: (json['questionId'] ?? json['id'] ?? requestedQuestionId).toString(),
      isCorrect: json['isCorrect'] as bool? ?? json['correct'] as bool?,
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt(),
      yourScore: json['yourScore'] as num? ?? json['score'] as num?,
      opponentScore: json['opponentScore'] as num?,
    );
  }
}
