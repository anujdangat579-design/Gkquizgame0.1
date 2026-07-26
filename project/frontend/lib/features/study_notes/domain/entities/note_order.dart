import 'package:equatable/equatable.dart';

/// A Cashfree order created server-side (`ApiConstants.noteOrders`) for
/// one study-note purchase. Mirrors `PaymentOrder` (payment feature)
/// exactly - `orderId` + `paymentSessionId` are all
/// `CashfreeCheckoutService` needs to launch Web Checkout; nothing else
/// about Cashfree reaches the client. Kept as its own entity rather than
/// reusing `PaymentOrder` since it's tied to a `noteId`, not a
/// `competitionId`+`difficultyLevel` pair.
class NoteOrder extends Equatable {
  final String orderId;
  final String paymentSessionId;
  final num orderAmount;
  final String currency;

  const NoteOrder({
    required this.orderId,
    required this.paymentSessionId,
    required this.orderAmount,
    required this.currency,
  });

  @override
  List<Object?> get props => [orderId, paymentSessionId, orderAmount, currency];
}
