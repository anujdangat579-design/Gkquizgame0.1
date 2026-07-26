import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/payment_order_model.dart';
import '../models/payment_verification_model.dart';

/// Talks directly to `ApiConstants.paymentOrders` / `paymentOrderStatus`
/// (see those constants' doc comments for the endpoint-path caveat).
/// Throws [ServerException]/[NetworkException]/etc. (via [DioClient]),
/// which the repository catches and converts to Failures — same shape
/// as [CompetitionDetailsRemoteDataSource].
abstract class PaymentRemoteDataSource {
  Future<PaymentOrderModel> createOrder({
    required String competitionId,
    required String difficultyLevel,
  });

  Future<PaymentVerificationModel> verifyPayment(String orderId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final DioClient client;

  PaymentRemoteDataSourceImpl(this.client);

  @override
  Future<PaymentOrderModel> createOrder({
    required String competitionId,
    required String difficultyLevel,
  }) async {
    final response = await client.post(
      ApiConstants.paymentOrders,
      data: {
        'competitionId': competitionId,
        'difficulty': difficultyLevel,
      },
    );
    return PaymentOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaymentVerificationModel> verifyPayment(String orderId) async {
    final response = await client.get(ApiConstants.paymentOrderStatus(orderId));
    return PaymentVerificationModel.fromJson(response.data as Map<String, dynamic>);
  }
}
