import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_question_set.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.text,
    required super.options,
  });

  /// Field names are a best guess (same unconfirmed-schema caveat as
  /// `LiveCompetitionModel`/`CompetitionDetailsModel` — no confirmed
  /// schema for this player-facing endpoint yet). Accepts either
  /// `text`/`question` for the prompt and `options`/`choices` for the
  /// four answers, since which the backend uses wasn't known ahead of
  /// time. Update the field names here once the real response shape is
  /// known.
  ///
  /// Intentionally does not read a "correct option" field even if the
  /// backend happens to send one — see `ApiConstants.matchQuestions`'s
  /// doc comment.
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] ?? json['choices']) as List<dynamic>?;

    return QuestionModel(
      id: (json['id'] ?? json['_id'] ?? json['questionId']).toString(),
      text: (json['text'] ?? json['question'] ?? json['prompt'] ?? '').toString(),
      options: rawOptions?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Accepts either a bare JSON array or `{ "questions": [...] }`,
  /// matching `LiveCompetitionModel.listFromJson`'s defensive shape for
  /// the same reason: the exact envelope isn't known.
  static List<QuestionModel> listFromJson(dynamic data) {
    final List<dynamic> raw = data is Map<String, dynamic>
        ? (data['questions'] as List<dynamic>? ?? const [])
        : (data as List<dynamic>? ?? const []);
    return raw.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// Wraps [QuestionModel.listFromJson]'s question list with the
/// match-level timing `QuizPage` needs for a server-synced countdown
/// (see `QuizQuestionSet`'s doc comment).
class QuizQuestionSetModel extends QuizQuestionSet {
  const QuizQuestionSetModel({
    required super.questions,
    super.matchStartedAt,
    super.secondsPerQuestion,
  });

  /// Same envelope caveat as `QuestionModel.listFromJson`: accepts
  /// either a bare JSON array (no timing available, so both fields
  /// come back null and `QuizPage` falls back to a local countdown) or
  /// an object carrying `questions` alongside timing.
  ///
  /// Timing field names are a best guess — no confirmed schema yet, so
  /// this tries `matchStartedAt`/`startedAt`/`startTime` for the shared
  /// match start (either an ISO 8601 string or an epoch timestamp) and
  /// `secondsPerQuestion`/`perQuestionSeconds`/`timePerQuestion` for the
  /// per-question window. Update these once the real response shape is
  /// known.
  factory QuizQuestionSetModel.fromJson(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return QuizQuestionSetModel(questions: QuestionModel.listFromJson(data));
    }

    final rawSeconds = data['secondsPerQuestion'] ?? data['perQuestionSeconds'] ?? data['timePerQuestion'];

    return QuizQuestionSetModel(
      questions: QuestionModel.listFromJson(data),
      matchStartedAt: _parseServerTimestamp(data['matchStartedAt'] ?? data['startedAt'] ?? data['startTime']),
      secondsPerQuestion: (rawSeconds as num?)?.toInt(),
    );
  }

  /// Accepts an ISO 8601 string, epoch milliseconds, or epoch seconds
  /// (distinguished by magnitude — a millisecond value this small would
  /// fall in 1970), always normalized to UTC so it lines up with
  /// `ServerClock.now()`.
  static DateTime? _parseServerTimestamp(dynamic raw) {
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    if (raw is num) {
      final isLikelyMilliseconds = raw > 100000000000;
      final ms = isLikelyMilliseconds ? raw.toInt() : (raw * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    return null;
  }
}
