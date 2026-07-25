import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment_verification.dart';
import '../repositories/payment_repository.dart';

/// Takes the order id directly as `Params` (no wrapper class needed) —
/// same shape as `GetCompetitionDetails` / `DeleteCompetition`.
class VerifyPayment implements UseCase<PaymentVerification, String> {
  final PaymentRepository repository;

  VerifyPayment(this.repository);

  @override
  Future<Either<Failure, PaymentVerification>> call(String orderId) {
    return repository.verifyPayment(orderId);
  }
}
