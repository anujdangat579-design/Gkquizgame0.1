import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/note_order.dart';
import '../entities/note_purchase_verification.dart';

/// Contract for the "Buy Notes" flow. Deliberately its own repository
/// rather than extending `PaymentRepository` (payment feature) - that
/// one's `createOrder` is shaped around `competitionId`+`difficultyLevel`,
/// which doesn't fit a single-priced note purchase. `BuyNoteNotifier`
/// still reuses `CashfreeCheckoutService` from the payment feature for
/// the actual checkout UI, same as `JoinCompetitionNotifier` does - only
/// order creation/verification are note-specific.
abstract class NotePaymentRepository {
  /// Creates a Cashfree order for `noteId`. The backend determines the
  /// amount from its own pricing, not from anything the client sends.
  Future<Either<Failure, NoteOrder>> createOrder(String noteId);

  /// Confirms `orderId`'s final status server-side, after the Cashfree
  /// checkout SDK has returned control to the app.
  Future<Either<Failure, NotePurchaseVerification>> verifyPayment(String orderId);
}
