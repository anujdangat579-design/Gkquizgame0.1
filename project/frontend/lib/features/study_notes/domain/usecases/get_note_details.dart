import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNoteDetails implements UseCase<Note, String> {
  final NoteRepository repository;

  GetNoteDetails(this.repository);

  @override
  Future<Either<Failure, Note>> call(String noteId) {
    return repository.getNoteDetails(noteId);
  }
}
