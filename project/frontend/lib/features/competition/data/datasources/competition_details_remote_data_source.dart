import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/competition_details_model.dart';

/// Talks directly to `ApiConstants.competitionDetails(id)` (see that
/// method's doc comment for the endpoint-path caveat). Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures — same shape as
/// [LiveCompetitionRemoteDataSource].
abstract class CompetitionDetailsRemoteDataSource {
  Future<CompetitionDetailsModel> getCompetitionDetails(String id);
}

class CompetitionDetailsRemoteDataSourceImpl implements CompetitionDetailsRemoteDataSource {
  final DioClient client;

  CompetitionDetailsRemoteDataSourceImpl(this.client);

  @override
  Future<CompetitionDetailsModel> getCompetitionDetails(String id) async {
    final response = await client.get(ApiConstants.competitionDetails(id));
    return CompetitionDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
