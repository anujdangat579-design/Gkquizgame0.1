import 'package:equatable/equatable.dart';

/// A Cashfree order created server-side (`ApiConstants.paymentOrders`)
/// for one competition entry-fee payment. `orderId` + `paymentSessionId`
/// are exactly what `CashfreeCheckoutService` needs to build a
/// `CFSession` and launch the Web Checkout SDK — nothing else about
/// Cashfree (API keys, customer details) ever reaches the client.
class PaymentOrder extends Equatable {
  final String orderId;
  final String paymentSessionId;
  final num orderAmount;
  final String currency;

  const PaymentOrder({
    required this.orderId,
    required this.paymentSessionId,
    required this.orderAmount,
    required this.currency,
  });

  @override
  List<Object?> get props => [orderId, paymentSessionId, orderAmount, currency];
}
