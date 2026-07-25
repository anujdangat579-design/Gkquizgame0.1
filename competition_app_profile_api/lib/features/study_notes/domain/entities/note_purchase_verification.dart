import 'package:equatable/equatable.dart';

/// Server-confirmed status of a note-purchase Cashfree order - never
/// derived from the checkout SDK's own callbacks, same caveat as
/// `PaymentVerification` (payment feature). `purchased` reflects
/// whether the backend also unlocked the note for this player, assumed
/// to happen atomically with marking the order `PAID` (mirrors
/// `PaymentVerification.joined`'s assumption).
enum NotePaymentStatus { success, pending, failed }

class NotePurchaseVerification extends Equatable {
  final String orderId;
  final NotePaymentStatus status;
  final String message;
  final bool purchased;

  const NotePurchaseVerification({
    required this.orderId,
    required this.status,
    required this.message,
    required this.purchased,
  });

  @override
  List<Object?> get props => [orderId, status, message, purchased];
}
