import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';

/// Talks directly to `/api/admin/profile`. Throws
/// [ServerException]/[NetworkException]/[UnauthorizedException] (via
/// [DioClient]), which the repository catches and converts to Failures.
abstract class AccountRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile({
    String? name,
    String? username,
    DateTime? dateOfBirth,
    String? gender,
  });
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final DioClient client;

  AccountRemoteDataSourceImpl(this.client);

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await client.get(ApiConstants.profile);
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? name,
    String? username,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final response = await client.patch(
      ApiConstants.profile,
      data: UserProfileModel.toUpdateJson(
        name: name,
        username: username,
        dateOfBirth: dateOfBirth,
        gender: gender,
      ),
    );
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }
}
