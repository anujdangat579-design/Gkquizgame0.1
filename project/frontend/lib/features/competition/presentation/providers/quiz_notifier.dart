import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/usecases/get_match_result.dart';
import '../../domain/usecases/get_quiz_questions.dart';
import '../../domain/usecases/submit_answer.dart';
import 'quiz_state.dart';

/// `ref.watch(quizNotifierProvider)` gives the current [QuizState];
/// `ref.read(...notifier)` gives access to [loadQuestions]/
/// [submitAnswer]/[loadMatchResult]. Use cases come from get_it (`sl`) —
/// same split as `liveCompetitionNotifierProvider`.
final quizNotifierProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(getQuizQuestions: sl(), submitAnswerUseCase: sl(), getMatchResultUseCase: sl());
});

class QuizNotifier extends StateNotifier<QuizState> {
  final GetQuizQuestions getQuizQuestions;
  final SubmitAnswer submitAnswerUseCase;
  final GetMatchResult getMatchResultUseCase;

  QuizNotifier({
    required this.getQuizQuestions,
    required this.submitAnswerUseCase,
    required this.getMatchResultUseCase,
  }) : super(const QuizState());

  Future<void> loadQuestions({required String queueId}) async {
    state = state.copyWith(viewState: QuizViewState.loading, clearError: true);

    final result = await getQuizQuestions(GetQuizQuestionsParams(queueId: queueId));

    result.fold(
      (failure) {
        AppLogger.warning('loadQuestions failed: ${failure.message}', tag: 'Quiz');
        state = state.copyWith(viewState: QuizViewState.error, errorMessage: failure.message);
      },
      (questionSet) {
        state = state.copyWith(
          viewState: QuizViewState.loaded,
          questions: questionSet.questions,
          matchStartedAt: questionSet.matchStartedAt,
          secondsPerQuestion: questionSet.secondsPerQuestion,
          clearError: true,
        );
      },
    );
  }

  /// Fires the submission for one question and, on success, stashes the
  /// response as `state.lastAnswerResult`. Deliberately never throws and
  /// never touches `viewState`/`questions` — a failed submission is only
  /// logged (see the doc comment on `QuizState.lastAnswerResult`) so
  /// `QuizPage` can await this and then advance to the next question
  /// regardless of the outcome, rather than getting stuck mid-match over
  /// a dropped network call.
  Future<void> submitAnswer({
    required String queueId,
    required String questionId,
    int? selectedOptionIndex,
  }) async {
    final result = await submitAnswerUseCase(
      SubmitAnswerParams(
        queueId: queueId,
        questionId: questionId,
        selectedOptionIndex: selectedOptionIndex,
      ),
    );

    result.fold(
      (failure) => AppLogger.warning('submitAnswer failed: ${failure.message}', tag: 'Quiz'),
      (answerResult) => state = state.copyWith(lastAnswerResult: answerResult),
    );
  }

  /// Fetches the settled outcome for this match once every question has
  /// been submitted (see `ApiConstants.matchResult`'s doc comment).
  /// Stashes the result as `state.matchResult` on success; on failure,
  /// only logs — mirroring `submitAnswer`'s fail-soft shape — and
  /// returns null so `QuizPage` can fall back to its placeholder
  /// summary rather than getting stuck after the match is already over.
  Future<MatchResult?> loadMatchResult({required String queueId}) async {
    final result = await getMatchResultUseCase(GetMatchResultParams(queueId: queueId));

    return result.fold(
      (failure) {
        AppLogger.warning('loadMatchResult failed: ${failure.message}', tag: 'Quiz');
        return null;
      },
      (matchResult) {
        state = state.copyWith(matchResult: matchResult);
        return matchResult;
      },
    );
  }
}
