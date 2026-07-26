import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_statistics_model.dart';

/// Talks directly to `/api/admin/dashboard/statistics`. Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures.
abstract class DashboardRemoteDataSource {
  Future<DashboardStatisticsModel> getStatistics();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient client;

  DashboardRemoteDataSourceImpl(this.client);

  @override
  Future<DashboardStatisticsModel> getStatistics() async {
    final response = await client.get(ApiConstants.dashboardStatistics);
    return DashboardStatisticsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
