import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_order.dart';
import '../repositories/note_payment_repository.dart';

class CreateNoteOrder implements UseCase<NoteOrder, String> {
  final NotePaymentRepository repository;

  CreateNoteOrder(this.repository);

  @override
  Future<Either<Failure, NoteOrder>> call(String noteId) {
    return repository.createOrder(noteId);
  }
}
