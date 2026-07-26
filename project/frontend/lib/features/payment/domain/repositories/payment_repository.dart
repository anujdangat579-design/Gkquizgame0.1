import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment_order.dart';
import '../entities/payment_verification.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (PaymentRepositoryImpl); the presentation
/// layer never talks to it directly, only through the `CreatePaymentOrder`
/// / `VerifyPayment` use cases — same shape as every other feature here.
abstract class PaymentRepository {
  /// Creates a Cashfree order for `competitionId` at the chosen
  /// `difficultyLevel` (one of `DifficultyPricing.level`). The backend
  /// determines the amount from its own pricing, not from anything the
  /// client sends, so a tampered client request can't join at a
  /// discount.
  Future<Either<Failure, PaymentOrder>> createOrder({
    required String competitionId,
    required String difficultyLevel,
  });

  /// Confirms `orderId`'s final status server-side, after the Cashfree
  /// checkout SDK has returned control to the app.
  Future<Either<Failure, PaymentVerification>> verifyPayment(String orderId);
}
