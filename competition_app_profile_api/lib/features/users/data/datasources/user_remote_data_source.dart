import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_user_model.dart';

class UserPageModel {
  final List<AdminUserModel> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const UserPageModel({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  /// Mirrors `CompetitionPageModel.fromJson`'s envelope shape:
  /// `{ users: [...], pagination: { page, limit, total, totalPages } }`.
  factory UserPageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['users'] as List<dynamic>? ?? const [])
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return UserPageModel(
      users: list,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? list.length,
      total: pagination['total'] as int? ?? list.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

/// Talks directly to `/api/admin/users`. Throws
/// [ServerException]/[NetworkException]/etc. (via [DioClient]), which
/// the repository catches and converts to Failures. Mirrors
/// `CompetitionRemoteDataSource`'s shape/conventions.
abstract class UserRemoteDataSource {
  Future<UserPageModel> getUsers({int page, int limit, String? search});
  Future<AdminUserModel> getUserById(String id);
  Future<AdminUserModel> createUser({
    required String name,
    required String email,
    String? phone,
    String? password,
  });
  Future<AdminUserModel> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
  });
  Future<AdminUserModel> setStatus({required String id, required bool active});
  Future<void> deleteUser(String id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient client;

  UserRemoteDataSourceImpl(this.client);

  @override
  Future<UserPageModel> getUsers({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? search,
  }) async {
    final response = await client.get(
      ApiConstants.users,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return UserPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> getUserById(String id) async {
    final response = await client.get(ApiConstants.userById(id));
    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> createUser({
    required String name,
    required String email,
    String? phone,
    String? password,
  }) async {
    final response = await client.post(
      ApiConstants.users,
      data: AdminUserModel.toCreateJson(name: name, email: email, phone: phone, password: password),
    );
    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
  }) async {
    final response = await client.patch(
      ApiConstants.userById(id),
      data: AdminUserModel.toUpdateJson(name: name, email: email, phone: phone),
    );
    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AdminUserModel> setStatus({required String id, required bool active}) async {
    final path = active ? ApiConstants.unblockUser(id) : ApiConstants.blockUser(id);
    final response = await client.patch(path);
    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(String id) async {
    await client.delete(ApiConstants.userById(id));
  }
}
