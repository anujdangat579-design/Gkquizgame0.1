import 'package:equatable/equatable.dart';

enum BuyNoteViewState { idle, creatingOrder, awaitingCheckout, verifying, purchased, error }

/// Immutable state for one note's buy-and-pay flow. Mirrors
/// `JoinCompetitionState`'s shape (payment feature), minus the
/// matchmaking hop that flow has and this one doesn't need.
class BuyNoteState extends Equatable {
  final BuyNoteViewState viewState;
  final String? errorMessage;

  const BuyNoteState({this.viewState = BuyNoteViewState.idle, this.errorMessage});

  bool get isInProgress =>
      viewState == BuyNoteViewState.creatingOrder ||
      viewState == BuyNoteViewState.awaitingCheckout ||
      viewState == BuyNoteViewState.verifying;

  BuyNoteState copyWith({
    BuyNoteViewState? viewState,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BuyNoteState(
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, errorMessage];
}
