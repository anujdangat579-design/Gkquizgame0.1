import 'package:equatable/equatable.dart';

/// Server-confirmed status of a Cashfree order — never derived from the
/// checkout SDK's own callbacks, which only signal that the checkout
/// *UI* finished, not whether Cashfree actually captured the payment.
/// Mirrors Cashfree's own `order_status` values relevant to a one-shot
/// entry-fee payment (`ACTIVE` before payment, `PAID` on success,
/// everything else treated as failed — see `PaymentVerificationModel`).
enum PaymentStatus { success, pending, failed }

/// Result of confirming a [PaymentOrder] against the backend
/// (`ApiConstants.paymentOrderStatus`). `joined` reflects whether the
/// backend also finalized the player's entry into the competition —
/// assumed to happen atomically with marking the order `PAID` (see that
/// constant's doc comment) so the client never has to make two calls.
class PaymentVerification extends Equatable {
  final String orderId;
  final PaymentStatus status;
  final String message;
  final bool joined;

  const PaymentVerification({
    required this.orderId,
    required this.status,
    required this.message,
    required this.joined,
  });

  @override
  List<Object?> get props => [orderId, status, message, joined];
}
