import 'package:equatable/equatable.dart';

/// A study-notes subject category (e.g. "Science", "History"), used to
/// filter `NotesListPage`. Mirrors `Category` (competition feature)'s
/// shape deliberately — same "backend icon key, not Flutter IconData"
/// rule applies here (see that class's doc comment); `NoteCategoryGrid`
/// is what resolves `iconKey` to a real icon.
class NoteCategory extends Equatable {
  final String id;
  final String name;
  final String iconKey;

  /// Best-effort count of notes in this category, shown as a subtitle
  /// on the category card. Null when the backend doesn't send one.
  final int? noteCount;

  const NoteCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    this.noteCount,
  });

  @override
  List<Object?> get props => [id, name, iconKey, noteCount];
}
