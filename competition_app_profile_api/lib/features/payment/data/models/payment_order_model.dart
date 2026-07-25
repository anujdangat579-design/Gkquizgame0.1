import '../../domain/entities/payment_order.dart';

class PaymentOrderModel extends PaymentOrder {
  const PaymentOrderModel({
    required super.orderId,
    required super.paymentSessionId,
    required super.orderAmount,
    required super.currency,
  });

  /// TODO(backend): field names are a best guess (no confirmed schema
  /// for `ApiConstants.paymentOrders` yet) — update once the real
  /// response shape is known. Falls back to Cashfree's own `/pg/orders`
  /// response field names (`cf_order_id`/`order_amount`/
  /// `order_currency`) in case the backend proxies that response through
  /// unchanged instead of wrapping it.
  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      orderId: (json['orderId'] ?? json['order_id'] ?? json['cf_order_id'] ?? '').toString(),
      paymentSessionId:
          (json['paymentSessionId'] ?? json['payment_session_id'] ?? '').toString(),
      orderAmount: (json['orderAmount'] as num?) ?? (json['order_amount'] as num?) ?? 0,
      currency:
          (json['currency'] ?? json['order_currency'])?.toString() ?? 'INR',
    );
  }
}
