import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/live_competition_model.dart';

/// Talks directly to `ApiConstants.liveCompetitions` (see that field's
/// doc comment for why the path is a best guess). Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures — same shape as
/// [CategoryRemoteDataSource].
abstract class LiveCompetitionRemoteDataSource {
  Future<List<LiveCompetitionModel>> getLiveCompetitions({String? category});
}

class LiveCompetitionRemoteDataSourceImpl implements LiveCompetitionRemoteDataSource {
  final DioClient client;

  LiveCompetitionRemoteDataSourceImpl(this.client);

  @override
  Future<List<LiveCompetitionModel>> getLiveCompetitions({String? category}) async {
    final response = await client.get(
      ApiConstants.liveCompetitions,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    return LiveCompetitionModel.listFromJson(response.data);
  }
}
