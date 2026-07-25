import '../../domain/entities/payment_verification.dart';

class PaymentVerificationModel extends PaymentVerification {
  const PaymentVerificationModel({
    required super.orderId,
    required super.status,
    required super.message,
    required super.joined,
  });

  /// TODO(backend): field names are a best guess (no confirmed schema
  /// for `ApiConstants.paymentOrderStatus` yet) — update once the real
  /// response shape is known. `status` accepts either a backend-specific
  /// value or Cashfree's own `order_status` passed straight through
  /// (`PAID` / `ACTIVE` / `EXPIRED` / `TERMINATED` / `TERMINATION_REQUESTED`)
  /// in case the backend doesn't normalize it — see the note on
  /// `ApiConstants.paymentOrderStatus` for why `PAID` is the only status
  /// treated as success rather than assuming "anything not failed".
  factory PaymentVerificationModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? json['order_status'] ?? '').toString().toUpperCase();
    return PaymentVerificationModel(
      orderId: (json['orderId'] ?? json['order_id'] ?? '').toString(),
      status: _parseStatus(rawStatus),
      message: json['message']?.toString() ?? _defaultMessage(_parseStatus(rawStatus)),
      joined: (json['joined'] as bool?) ?? rawStatus == 'PAID',
    );
  }

  static PaymentStatus _parseStatus(String rawStatus) {
    switch (rawStatus) {
      case 'PAID':
      case 'SUCCESS':
        return PaymentStatus.success;
      case 'ACTIVE':
      case 'PENDING':
        return PaymentStatus.pending;
      default:
        return PaymentStatus.failed;
    }
  }

  static String _defaultMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return 'Payment confirmed';
      case PaymentStatus.pending:
        return 'Payment is still processing';
      case PaymentStatus.failed:
        return 'Payment was not completed';
    }
  }
}
