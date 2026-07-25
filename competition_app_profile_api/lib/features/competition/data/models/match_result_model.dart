import '../../domain/entities/match_result.dart';

class MatchResultPlayerModel extends MatchResultPlayer {
  const MatchResultPlayerModel({
    required super.name,
    super.photoUrl,
    super.rankLabel,
  });

  /// Field names are a best guess, same unconfirmed-schema caveat as
  /// `QuestionModel` — accepts `name`/`playerName`, `photoUrl`/`avatarUrl`,
  /// `rankLabel`/`rank`. Falls back to "Unranked" (matching `QueuePlayer`'s
  /// own default) if the backend doesn't send a rank at all.
  factory MatchResultPlayerModel.fromJson(Map<String, dynamic> json, {required String fallbackName}) {
    return MatchResultPlayerModel(
      name: (json['name'] ?? json['playerName'] ?? fallbackName).toString(),
      photoUrl: (json['photoUrl'] ?? json['avatarUrl'])?.toString(),
      rankLabel: (json['rankLabel'] ?? json['rank'])?.toString() ?? 'Unranked',
    );
  }
}

class MatchResultQuestionModel extends MatchResultQuestion {
  const MatchResultQuestionModel({
    required super.number,
    required super.question,
    required super.yourAnswer,
    required super.correctAnswer,
    required super.wasSkipped,
    required super.isCorrect,
    required super.timeTakenSeconds,
  });

  /// Same unconfirmed-schema caveat as everything else here. `number` is
  /// 1-based, falling back to the item's position in the list if the
  /// backend doesn't send one explicitly.
  factory MatchResultQuestionModel.fromJson(Map<String, dynamic> json, {required int fallbackNumber}) {
    final yourAnswer = (json['yourAnswer'] ?? json['selectedOption'])?.toString();
    return MatchResultQuestionModel(
      number: (json['number'] as num?)?.toInt() ?? fallbackNumber,
      question: (json['question'] ?? json['text'] ?? '').toString(),
      yourAnswer: yourAnswer,
      correctAnswer: (json['correctAnswer'] ?? json['correctOption'] ?? '').toString(),
      wasSkipped: json['wasSkipped'] as bool? ?? yourAnswer == null,
      isCorrect: json['isCorrect'] as bool? ?? json['correct'] as bool? ?? false,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class MatchResultModel extends MatchResult {
  const MatchResultModel({
    required super.matchId,
    required super.you,
    required super.opponent,
    required super.yourScore,
    required super.opponentScore,
    required super.correctAnswers,
    required super.totalQuestions,
    required super.timeTakenSeconds,
    required super.category,
    super.questionBreakdown,
  });

  /// Field names are a best guess — no confirmed schema yet for
  /// `ApiConstants.matchResult` (see that constant's doc comment).
  /// `you`/`opponent` fall back to a bare name if the backend sends a
  /// player as a plain string rather than an object. `questionBreakdown`
  /// is left null (rather than an empty list) when the backend doesn't
  /// send one at all, so callers can tell "no breakdown yet" apart from
  /// "a genuinely empty match".
  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] ?? json['questionBreakdown'];

    return MatchResultModel(
      matchId: (json['matchId'] ?? json['id'] ?? '').toString(),
      you: _parsePlayer(json['you'] ?? json['player'], fallbackName: 'You'),
      opponent: _parsePlayer(json['opponent'], fallbackName: 'Opponent'),
      yourScore: (json['yourScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? 'General Knowledge').toString(),
      questionBreakdown: rawQuestions is List<dynamic>
          ? [
              for (int i = 0; i < rawQuestions.length; i++)
                MatchResultQuestionModel.fromJson(rawQuestions[i] as Map<String, dynamic>, fallbackNumber: i + 1),
            ]
          : null,
    );
  }

  static MatchResultPlayerModel _parsePlayer(dynamic raw, {required String fallbackName}) {
    if (raw is Map<String, dynamic>) {
      return MatchResultPlayerModel.fromJson(raw, fallbackName: fallbackName);
    }
    if (raw is String) return MatchResultPlayerModel(name: raw);
    return MatchResultPlayerModel(name: fallbackName);
  }
}
