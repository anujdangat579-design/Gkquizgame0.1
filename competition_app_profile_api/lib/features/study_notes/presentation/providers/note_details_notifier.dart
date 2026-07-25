import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_note_details.dart';
import 'note_details_state.dart';

/// Keyed by note id via `.family` + `.autoDispose` - mirrors
/// `competitionDetailsNotifierProvider`.
final noteDetailsNotifierProvider = StateNotifierProvider.autoDispose
    .family<NoteDetailsNotifier, NoteDetailsState, String>((ref, noteId) {
  return NoteDetailsNotifier(noteId: noteId, getNoteDetails: sl());
});

class NoteDetailsNotifier extends StateNotifier<NoteDetailsState> {
  final String noteId;
  final GetNoteDetails getNoteDetails;

  NoteDetailsNotifier({required this.noteId, required this.getNoteDetails})
      : super(const NoteDetailsState());

  Future<void> loadDetails() async {
    state = state.copyWith(viewState: NoteDetailsViewState.loading, clearError: true);

    final result = await getNoteDetails(noteId);

    result.fold(
      (failure) {
        AppLogger.warning('loadNoteDetails($noteId) failed: ${failure.message}', tag: 'StudyNotes');
        state = state.copyWith(viewState: NoteDetailsViewState.error, errorMessage: failure.message);
      },
      (note) {
        state = state.copyWith(viewState: NoteDetailsViewState.loaded, note: note, clearError: true);
      },
    );
  }

  /// Marks the currently-loaded note as purchased without a refetch, so
  /// `NoteDetailsPage` can flip to "Open in My Library" the instant
  /// `BuyNoteNotifier.buy` succeeds instead of waiting on a round trip.
  void markPurchased() {
    final current = state.note;
    if (current == null) return;
    state = state.copyWith(
      note: Note(
        id: current.id,
        title: current.title,
        price: current.price,
        currency: current.currency,
        subject: current.subject,
        categoryId: current.categoryId,
        description: current.description,
        thumbnailUrl: current.thumbnailUrl,
        authorName: current.authorName,
        pageCount: current.pageCount,
        rating: current.rating,
        isPurchased: true,
      ),
    );
  }
}
