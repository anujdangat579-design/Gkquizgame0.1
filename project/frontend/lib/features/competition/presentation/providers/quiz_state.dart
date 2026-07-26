import 'package:equatable/equatable.dart';

import '../../domain/entities/answer_result.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/entities/question.dart';

enum QuizViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `LiveCompetitionState`'s shape (a single unpaginated list, no
/// mutations) — `QuizPage` only ever needs the full question set for
/// its `queueId` up front, not paged/mutated one at a time.
class QuizState extends Equatable {
  final QuizViewState viewState;
  final List<Question> questions;
  final String? errorMessage;

  /// The most recent `submitAnswer` response, if any. Submission
  /// failures are logged (see `QuizNotifier.submitAnswer`) but never
  /// surfaced here or block `viewState` — a dropped answer submission
  /// shouldn't stall the match the way a failed question-set load
  /// should, since `QuizPage` already advances locally regardless of
  /// whether the submission succeeded.
  final AnswerResult? lastAnswerResult;

  /// Server-issued match-start time and per-question window, from
  /// `QuizQuestionSet` — see that entity's doc comment. Null when the
  /// backend hasn't sent timing info yet, in which case `QuizPage`
  /// falls back to its old fully-local, un-synced countdown.
  final DateTime? matchStartedAt;
  final int? secondsPerQuestion;

  /// The settled outcome for this match, once `loadMatchResult` has
  /// succeeded — see `QuizNotifier.loadMatchResult`'s doc comment. Null
  /// until then (or if that fetch failed), in which case `QuizPage`
  /// falls back to a placeholder summary built from local state.
  final MatchResult? matchResult;

  const QuizState({
    this.viewState = QuizViewState.initial,
    this.questions = const [],
    this.errorMessage,
    this.lastAnswerResult,
    this.matchStartedAt,
    this.secondsPerQuestion,
    this.matchResult,
  });

  QuizState copyWith({
    QuizViewState? viewState,
    List<Question>? questions,
    String? errorMessage,
    bool clearError = false,
    AnswerResult? lastAnswerResult,
    DateTime? matchStartedAt,
    int? secondsPerQuestion,
    MatchResult? matchResult,
  }) {
    return QuizState(
      viewState: viewState ?? this.viewState,
      questions: questions ?? this.questions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastAnswerResult: lastAnswerResult ?? this.lastAnswerResult,
      matchStartedAt: matchStartedAt ?? this.matchStartedAt,
      secondsPerQuestion: secondsPerQuestion ?? this.secondsPerQuestion,
      matchResult: matchResult ?? this.matchResult,
    );
  }

  @override
  List<Object?> get props => [
        viewState,
        questions,
        errorMessage,
        lastAnswerResult,
        matchStartedAt,
        secondsPerQuestion,
        matchResult,
      ];
}
