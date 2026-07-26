import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_purchase_verification.dart';
import '../repositories/note_payment_repository.dart';

class VerifyNotePayment implements UseCase<NotePurchaseVerification, String> {
  final NotePaymentRepository repository;

  VerifyNotePayment(this.repository);

  @override
  Future<Either<Failure, NotePurchaseVerification>> call(String orderId) {
    return repository.verifyPayment(orderId);
  }
}
