import 'package:equatable/equatable.dart';

enum FeedbackViewState { idle, submitting, success, error }

/// Immutable state Riverpod's StateNotifier emits for the winner
/// feedback submission. Mirrors `QuizState`'s shape — a single in-flight
/// action with an error message, rather than a loaded list.
class WinnerFeedbackState extends Equatable {
  final FeedbackViewState viewState;
  final String? errorMessage;

  const WinnerFeedbackState({
    this.viewState = FeedbackViewState.idle,
    this.errorMessage,
  });

  WinnerFeedbackState copyWith({
    FeedbackViewState? viewState,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WinnerFeedbackState(
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, errorMessage];
}
