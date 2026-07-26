import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/note.dart';

enum NotesViewState { initial, loading, loaded, error }

/// One loaded page of notes, replaced on reload/pull-to-refresh -
/// mirrors `PurchasedNotesState`'s shape.
class NotesState extends Equatable {
  final NotesViewState viewState;
  final List<Note> notes;
  final String? errorMessage;
  final int page;
  final int totalPages;

  const NotesState({
    this.viewState = NotesViewState.initial,
    this.notes = const [],
    this.errorMessage,
    this.page = AppConstants.defaultPage,
    this.totalPages = 1,
  });

  NotesState copyWith({
    NotesViewState? viewState,
    List<Note>? notes,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? totalPages,
  }) {
    return NotesState(
      viewState: viewState ?? this.viewState,
      notes: notes ?? this.notes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [viewState, notes, errorMessage, page, totalPages];
}
