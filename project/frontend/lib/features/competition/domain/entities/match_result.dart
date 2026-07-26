import 'package:equatable/equatable.dart';

/// A player's identity + rank as it comes back with the match result —
/// same shape `QueuePlayer` (a UI-only class in `opponent_found_page.dart`)
/// mirrors, but this is the domain source of truth for how the match
/// actually settled, rather than whatever was passed forward from
/// matchmaking.
class MatchResultPlayer extends Equatable {
  final String name;
  final String? photoUrl;
  final String rankLabel;

  const MatchResultPlayer({
    required this.name,
    this.photoUrl,
    this.rankLabel = 'Unranked',
  });

  @override
  List<Object?> get props => [name, photoUrl, rankLabel];
}

/// One question's settled outcome, as (optionally) returned alongside
/// the match summary — mirrors `ScoreReportPage`'s local-only
/// `QuestionReport`, but sourced from the backend instead of
/// synthesized from just the aggregate correct/incorrect counts.
class MatchResultQuestion extends Equatable {
  final int number;
  final String question;
  final String? yourAnswer;
  final String correctAnswer;
  final bool wasSkipped;
  final bool isCorrect;
  final int timeTakenSeconds;

  const MatchResultQuestion({
    required this.number,
    required this.question,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.wasSkipped,
    required this.isCorrect,
    required this.timeTakenSeconds,
  });

  @override
  List<Object?> get props =>
      [number, question, yourAnswer, correctAnswer, wasSkipped, isCorrect, timeTakenSeconds];
}

/// The settled outcome of one completed match, from
/// `ApiConstants.matchResult`. Backs `ResultPage`'s summary and, when
/// [questionBreakdown] is non-null, `ScoreReportPage`'s per-question
/// detail — both previously ran on placeholder data synthesized
/// client-side (see `QuizPage._goToCompletedThenResult`'s old doc
/// comment).
class MatchResult extends Equatable {
  final String matchId;
  final MatchResultPlayer you;
  final MatchResultPlayer opponent;
  final int yourScore;
  final int opponentScore;
  final int correctAnswers;
  final int totalQuestions;
  final int timeTakenSeconds;
  final String category;

  /// Null when the backend doesn't send a per-question breakdown with
  /// the summary result yet — callers fall back to synthesizing a
  /// placeholder from the aggregate counts above, same as before this
  /// existed (see `ResultPage._handleViewFullReport`).
  final List<MatchResultQuestion>? questionBreakdown;

  const MatchResult({
    required this.matchId,
    required this.you,
    required this.opponent,
    required this.yourScore,
    required this.opponentScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.category,
    this.questionBreakdown,
  });

  @override
  List<Object?> get props => [
        matchId,
        you,
        opponent,
        yourScore,
        opponentScore,
        correctAnswers,
        totalQuestions,
        timeTakenSeconds,
        category,
        questionBreakdown,
      ];
}
