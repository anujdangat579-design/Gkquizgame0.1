import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_notes.dart';
import 'notes_state.dart';

/// Keyed by category id via `.family` (empty string = "all notes", used
/// by `NotesListPage` when it's reached without a category filter) so
/// browsing two different categories in the same session doesn't share
/// one page/list - same reasoning as `competitionDetailsNotifierProvider`.
final notesNotifierProvider =
    StateNotifierProvider.family<NotesNotifier, NotesState, String?>((ref, categoryId) {
  return NotesNotifier(categoryId: categoryId, getNotes: sl());
});

class NotesNotifier extends StateNotifier<NotesState> {
  final String? categoryId;
  final GetNotes getNotes;

  NotesNotifier({required this.categoryId, required this.getNotes}) : super(const NotesState());

  Future<void> loadNotes({int page = AppConstants.defaultPage, String? search}) async {
    state = state.copyWith(viewState: NotesViewState.loading, clearError: true);

    final result = await getNotes(
      GetNotesParams(categoryId: categoryId, search: search, page: page),
    );

    result.fold(
      (failure) {
        AppLogger.warning('loadNotes failed: ${failure.message}', tag: 'StudyNotes');
        state = state.copyWith(viewState: NotesViewState.error, errorMessage: failure.message);
      },
      (data) {
        state = state.copyWith(
          viewState: NotesViewState.loaded,
          notes: data.notes,
          page: data.page,
          totalPages: data.totalPages,
          clearError: true,
        );
      },
    );
  }
}
