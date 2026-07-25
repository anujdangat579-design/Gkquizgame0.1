import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/note_category.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (NoteCategoryRepositoryImpl); the
/// presentation layer never talks to it directly, only through
/// `GetNoteCategories`. Mirrors `CategoryRepository`'s shape.
abstract class NoteCategoryRepository {
  Future<Either<Failure, List<NoteCategory>>> getNoteCategories();
}
