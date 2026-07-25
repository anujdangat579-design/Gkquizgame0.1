import 'package:equatable/equatable.dart';

/// Server's response to submitting one answer via
/// `ApiConstants.submitAnswer`. Distinct from `Question` (which never
/// carries a correct-option field — see that entity's doc comment) since
/// this is returned only *after* the player has already committed an
/// answer, so revealing correctness here doesn't let them see ahead.
///
/// `yourScore`/`opponentScore` are nullable since a running score isn't
/// guaranteed to come back with every single-answer response (the
/// backend may only send it, say, once the whole match is scored) —
/// `QuizPage`/`ResultPage` should treat a null score as "not known yet"
/// rather than zero.
class AnswerResult extends Equatable {
  final String questionId;
  final bool? isCorrect;
  final int? correctOptionIndex;
  final num? yourScore;
  final num? opponentScore;

  const AnswerResult({
    required this.questionId,
    this.isCorrect,
    this.correctOptionIndex,
    this.yourScore,
    this.opponentScore,
  });

  @override
  List<Object?> get props => [questionId, isCorrect, correctOptionIndex, yourScore, opponentScore];
}
