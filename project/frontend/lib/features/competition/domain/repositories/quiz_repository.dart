import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/answer_result.dart';
import '../entities/match_result.dart';
import '../entities/quiz_question_set.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (QuizRepositoryImpl); the presentation layer
/// never talks to it directly, only through use cases. Mirrors
/// LiveCompetitionRepository's shape — a single unpaginated list, since
/// a match's full question set is handed to the client up front rather
/// than paged through one at a time.
abstract class QuizRepository {
  /// Returns the match's questions bundled with the server-issued
  /// timing (`QuizQuestionSet.matchStartedAt`/`secondsPerQuestion`)
  /// `QuizPage` needs to sync its per-question countdown against the
  /// server's clock rather than a purely local one.
  Future<Either<Failure, QuizQuestionSet>> getQuestions({required String queueId});

  /// Submits the player's answer for one question — `selectedOptionIndex`
  /// is null on a timeout auto-submit (see `QuizPage._handleAutoSubmit`).
  Future<Either<Failure, AnswerResult>> submitAnswer({
    required String queueId,
    required String questionId,
    int? selectedOptionIndex,
  });

  /// Fetches the settled outcome for a match once every question has
  /// been submitted — see `ApiConstants.matchResult`'s doc comment.
  Future<Either<Failure, MatchResult>> getMatchResult({required String queueId});
}
