import 'package:equatable/equatable.dart';

import 'question.dart';

/// The full question set for a match, plus the server-issued timing
/// needed to keep every player's per-question countdown in lockstep —
/// see `QuizPage`'s doc comment for why a purely device-local countdown
/// lets two players' clocks disagree.
///
/// [matchStartedAt]/[secondsPerQuestion] are nullable because the
/// backend's response schema for `ApiConstants.matchQuestions` isn't
/// confirmed yet (same caveat as `QuestionModel`) — `QuizPage` falls
/// back to its old fully-local, un-synced countdown when either is
/// missing, rather than crashing on a field that may not exist yet.
class QuizQuestionSet extends Equatable {
  final List<Question> questions;

  /// When the match's first question started, per the server's clock
  /// (already converted to UTC — see `QuizQuestionSetModel`). Combined
  /// with [secondsPerQuestion], this fixes every question's deadline
  /// without the backend needing to send one per question: the whole
  /// set is time-boxed back-to-back from this single shared instant.
  final DateTime? matchStartedAt;
  final int? secondsPerQuestion;

  const QuizQuestionSet({
    required this.questions,
    this.matchStartedAt,
    this.secondsPerQuestion,
  });

  /// Absolute server-clock deadline for the question at [index] (0-based),
  /// or null if the backend hasn't sent timing info yet — see the class
  /// doc comment. Compare against `ServerClock.instance.now()`, never
  /// `DateTime.now()` directly, or a device with a skewed clock will
  /// disagree with everyone else about how much time is left.
  DateTime? deadlineForQuestion(int index) {
    final startedAt = matchStartedAt;
    final perQuestion = secondsPerQuestion;
    if (startedAt == null || perQuestion == null) return null;
    return startedAt.add(Duration(seconds: perQuestion * (index + 1)));
  }

  @override
  List<Object?> get props => [questions, matchStartedAt, secondsPerQuestion];
}
