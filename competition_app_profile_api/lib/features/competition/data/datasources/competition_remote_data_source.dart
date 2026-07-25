import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/competition_model.dart';

class CompetitionPageModel {
  final List<CompetitionModel> competitions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const CompetitionPageModel({
    required this.competitions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CompetitionPageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['competitions'] as List<dynamic>)
        .map((e) => CompetitionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return CompetitionPageModel(
      competitions: list,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? list.length,
      total: pagination['total'] as int? ?? list.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

/// Talks directly to `/api/admin/competitions` on the backend from
/// competition-api.zip. Throws [ServerException]/[NetworkException]/etc.,
/// which the repository catches and converts to Failures.
abstract class CompetitionRemoteDataSource {
  Future<CompetitionPageModel> getCompetitions({int page, int limit, String? search});
  Future<CompetitionModel> getCompetitionById(String id);
  Future<CompetitionModel> createCompetition({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<CompetitionModel> updateCompetition({
    required String id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<CompetitionModel> setStatus({required String id, required bool enabled});
  Future<void> deleteCompetition(String id);
}

class CompetitionRemoteDataSourceImpl implements CompetitionRemoteDataSource {
  final DioClient client;

  CompetitionRemoteDataSourceImpl(this.client);

  @override
  Future<CompetitionPageModel> getCompetitions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? search,
  }) async {
    final response = await client.get(
      ApiConstants.competitions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return CompetitionPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CompetitionModel> getCompetitionById(String id) async {
    final response = await client.get(ApiConstants.competitionById(id));
    return CompetitionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CompetitionModel> createCompetition({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await client.post(
      ApiConstants.competitions,
      data: CompetitionModel.toCreateJson(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return CompetitionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CompetitionModel> updateCompetition({
    required String id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await client.patch(
      ApiConstants.competitionById(id),
      data: CompetitionModel.toUpdateJson(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
      ),
    );
    return CompetitionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CompetitionModel> setStatus({required String id, required bool enabled}) async {
    final path = enabled ? ApiConstants.enableCompetition(id) : ApiConstants.disableCompetition(id);
    final response = await client.patch(path);
    return CompetitionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCompetition(String id) async {
    await client.delete(ApiConstants.competitionById(id));
  }
}
