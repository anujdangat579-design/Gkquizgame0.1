import '../../domain/entities/note_purchase_verification.dart';

class NotePurchaseVerificationModel extends NotePurchaseVerification {
  const NotePurchaseVerificationModel({
    required super.orderId,
    required super.status,
    required super.message,
    required super.purchased,
  });

  factory NotePurchaseVerificationModel.fromJson(Map<String, dynamic> json) {
    return NotePurchaseVerificationModel(
      orderId: (json['orderId'] ?? json['order_id']).toString(),
      status: _statusFrom(json['status']?.toString()),
      message: json['message']?.toString() ?? '',
      purchased: json['purchased'] as bool? ?? false,
    );
  }

  // Mirrors PaymentVerificationModel's Cashfree order_status mapping:
  // `PAID` -> success, everything else conservatively treated as
  // pending/failed rather than assumed successful.
  static NotePaymentStatus _statusFrom(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PAID':
        return NotePaymentStatus.success;
      case 'ACTIVE':
        return NotePaymentStatus.pending;
      default:
        return NotePaymentStatus.failed;
    }
  }
}
