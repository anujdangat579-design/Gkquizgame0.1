import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';

enum NoteDetailsViewState { initial, loading, loaded, error }

/// Mirrors `CompetitionDetailsState`'s shape.
class NoteDetailsState extends Equatable {
  final NoteDetailsViewState viewState;
  final Note? note;
  final String? errorMessage;

  const NoteDetailsState({
    this.viewState = NoteDetailsViewState.initial,
    this.note,
    this.errorMessage,
  });

  NoteDetailsState copyWith({
    NoteDetailsViewState? viewState,
    Note? note,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NoteDetailsState(
      viewState: viewState ?? this.viewState,
      note: note ?? this.note,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, note, errorMessage];
}
