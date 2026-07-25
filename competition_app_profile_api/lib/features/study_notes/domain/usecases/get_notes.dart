import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/note_repository.dart';

class GetNotesParams extends Equatable {
  final String? categoryId;
  final String? search;
  final int page;
  final int limit;

  const GetNotesParams({
    this.categoryId,
    this.search,
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
  });

  @override
  List<Object?> get props => [categoryId, search, page, limit];
}

class GetNotes implements UseCase<NotesPage, GetNotesParams> {
  final NoteRepository repository;

  GetNotes(this.repository);

  @override
  Future<Either<Failure, NotesPage>> call(GetNotesParams params) {
    return repository.getNotes(
      categoryId: params.categoryId,
      search: params.search,
      page: params.page,
      limit: params.limit,
    );
  }
}
