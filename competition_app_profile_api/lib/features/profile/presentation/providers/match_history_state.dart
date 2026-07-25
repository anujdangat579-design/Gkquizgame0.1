import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/match_history_entry.dart';

enum MatchHistoryViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `CompetitionState`'s shape — a single loaded page, replaced on
/// reload/pull-to-refresh rather than accumulating via infinite scroll.
class MatchHistoryState extends Equatable {
  final MatchHistoryViewState viewState;
  final List<MatchHistoryEntry> entries;
  final String? errorMessage;
  final int page;
  final int totalPages;

  const MatchHistoryState({
    this.viewState = MatchHistoryViewState.initial,
    this.entries = const [],
    this.errorMessage,
    this.page = AppConstants.defaultPage,
    this.totalPages = 1,
  });

  MatchHistoryState copyWith({
    MatchHistoryViewState? viewState,
    List<MatchHistoryEntry>? entries,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? totalPages,
  }) {
    return MatchHistoryState(
      viewState: viewState ?? this.viewState,
      entries: entries ?? this.entries,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [viewState, entries, errorMessage, page, totalPages];
}
