import 'package:equatable/equatable.dart';

import '../../domain/entities/competition_details.dart';

enum CompetitionDetailsViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `LiveCompetitionState`'s shape — a single fetched record instead of
/// a list.
class CompetitionDetailsState extends Equatable {
  final CompetitionDetailsViewState viewState;
  final CompetitionDetails? details;
  final String? errorMessage;

  const CompetitionDetailsState({
    this.viewState = CompetitionDetailsViewState.initial,
    this.details,
    this.errorMessage,
  });

  CompetitionDetailsState copyWith({
    CompetitionDetailsViewState? viewState,
    CompetitionDetails? details,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CompetitionDetailsState(
      viewState: viewState ?? this.viewState,
      details: details ?? this.details,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, details, errorMessage];
}
