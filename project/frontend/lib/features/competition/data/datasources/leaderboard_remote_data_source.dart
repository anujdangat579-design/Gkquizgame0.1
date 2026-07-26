import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/leaderboard.dart';
import '../models/leaderboard_model.dart';

/// Talks directly to `ApiConstants.leaderboard` (see that constant's doc
/// comment for the endpoint-path caveat). Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures — same shape as
/// [QuizRemoteDataSource].
abstract class LeaderboardRemoteDataSource {
  Future<LeaderboardBoardModel> getLeaderboard({required LeaderboardRange range});
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final DioClient client;

  LeaderboardRemoteDataSourceImpl(this.client);

  @override
  Future<LeaderboardBoardModel> getLeaderboard({required LeaderboardRange range}) async {
    final response = await client.get(
      ApiConstants.leaderboard,
      queryParameters: {'range': range.apiValue},
    );
    return LeaderboardBoardModel.fromJson(response.data as Map<String, dynamic>);
  }
}
