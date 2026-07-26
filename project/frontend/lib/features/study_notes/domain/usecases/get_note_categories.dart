import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_category.dart';
import '../repositories/note_category_repository.dart';

class GetNoteCategories implements UseCase<List<NoteCategory>, NoParams> {
  final NoteCategoryRepository repository;

  GetNoteCategories(this.repository);

  @override
  Future<Either<Failure, List<NoteCategory>>> call(NoParams params) {
    return repository.getNoteCategories();
  }
}
