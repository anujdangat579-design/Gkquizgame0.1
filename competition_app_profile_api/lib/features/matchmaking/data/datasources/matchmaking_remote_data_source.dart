import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/matchmaking_entry_model.dart';

/// Talks directly to `ApiConstants.matchmakingQueue` /
/// `matchmakingQueueEntry` (see those constants' doc comments for the
/// endpoint-path caveat). Throws [ServerException]/[NetworkException]/etc.
/// (via [DioClient]), which the repository catches and converts to
/// Failures — same shape as [PaymentRemoteDataSource].
abstract class MatchmakingRemoteDataSource {
  Future<MatchmakingEntryModel> enterQueue({
    required String competitionId,
    required String orderId,
  });

  Future<MatchmakingEntryModel> getStatus(String queueId);

  Future<void> leaveQueue(String queueId);
}

class MatchmakingRemoteDataSourceImpl implements MatchmakingRemoteDataSource {
  final DioClient client;

  MatchmakingRemoteDataSourceImpl(this.client);

  @override
  Future<MatchmakingEntryModel> enterQueue({
    required String competitionId,
    required String orderId,
  }) async {
    final response = await client.post(
      ApiConstants.matchmakingQueue,
      data: {
        'competitionId': competitionId,
        'orderId': orderId,
      },
    );
    return MatchmakingEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MatchmakingEntryModel> getStatus(String queueId) async {
    final response = await client.get(ApiConstants.matchmakingQueueEntry(queueId));
    return MatchmakingEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> leaveQueue(String queueId) async {
    await client.delete(ApiConstants.matchmakingQueueEntry(queueId));
  }
}
