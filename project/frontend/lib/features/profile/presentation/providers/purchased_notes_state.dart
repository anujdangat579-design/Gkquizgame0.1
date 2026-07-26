import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/purchased_note.dart';

enum PurchasedNotesViewState { initial, loading, loaded, error }

/// Mirrors `MatchHistoryState`'s shape — a single loaded page, replaced
/// on reload/pull-to-refresh.
class PurchasedNotesState extends Equatable {
  final PurchasedNotesViewState viewState;
  final List<PurchasedNote> notes;
  final String? errorMessage;
  final int page;
  final int totalPages;

  const PurchasedNotesState({
    this.viewState = PurchasedNotesViewState.initial,
    this.notes = const [],
    this.errorMessage,
    this.page = AppConstants.defaultPage,
    this.totalPages = 1,
  });

  PurchasedNotesState copyWith({
    PurchasedNotesViewState? viewState,
    List<PurchasedNote>? notes,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? totalPages,
  }) {
    return PurchasedNotesState(
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
