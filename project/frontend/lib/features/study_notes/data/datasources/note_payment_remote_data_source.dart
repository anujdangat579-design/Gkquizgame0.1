import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/note_order_model.dart';
import '../models/note_purchase_verification_model.dart';

/// Talks directly to `ApiConstants.noteOrders`/`noteOrderStatus`.
/// Mirrors `PaymentRemoteDataSource`'s shape.
abstract class NotePaymentRemoteDataSource {
  Future<NoteOrderModel> createOrder(String noteId);
  Future<NotePurchaseVerificationModel> verifyPayment(String orderId);
}

class NotePaymentRemoteDataSourceImpl implements NotePaymentRemoteDataSource {
  final DioClient client;

  NotePaymentRemoteDataSourceImpl(this.client);

  @override
  Future<NoteOrderModel> createOrder(String noteId) async {
    final response = await client.post(
      ApiConstants.noteOrders,
      data: {'noteId': noteId},
    );
    return NoteOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<NotePurchaseVerificationModel> verifyPayment(String orderId) async {
    final response = await client.get(ApiConstants.noteOrderStatus(orderId));
    return NotePurchaseVerificationModel.fromJson(response.data as Map<String, dynamic>);
  }
}
