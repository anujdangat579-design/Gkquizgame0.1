import '../../domain/entities/note_order.dart';

class NoteOrderModel extends NoteOrder {
  const NoteOrderModel({
    required super.orderId,
    required super.paymentSessionId,
    required super.orderAmount,
    required super.currency,
  });

  factory NoteOrderModel.fromJson(Map<String, dynamic> json) {
    return NoteOrderModel(
      orderId: (json['orderId'] ?? json['order_id']).toString(),
      paymentSessionId: (json['paymentSessionId'] ?? json['payment_session_id']).toString(),
      orderAmount: (json['orderAmount'] ?? json['order_amount']) as num? ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}
