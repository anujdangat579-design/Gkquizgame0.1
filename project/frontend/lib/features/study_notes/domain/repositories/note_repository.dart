import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/note.dart';

/// Result of a paged notes fetch. Mirrors the shape
/// `CompetitionRepository`/`ProfileRepository` return for their own
/// paged lists (page/totalPages alongside the items) so
/// `NotesNotifier` can drive "load more" the same way
/// `PurchasedNotesNotifier` does.
class NotesPage {
  final List<Note> notes;
  final int page;
  final int totalPages;

  const NotesPage({required this.notes, required this.page, required this.totalPages});
}

abstract class NoteRepository {
  /// `categoryId` filters to one category; null/omitted returns notes
  /// across all categories (used by `NotesListPage` when reached
  /// without picking a category first).
  Future<Either<Failure, NotesPage>> getNotes({
    String? categoryId,
    String? search,
    required int page,
    required int limit,
  });

  Future<Either<Failure, Note>> getNoteDetails(String id);
}
