import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_model.dart';

/// Wraps the raw `{token, admin}` response so the repository doesn't deal
/// with the JSON shape directly — mirrors `CompetitionPageModel`'s role
/// for the competitions endpoint.
class LoginResponseModel {
  final String token;
  final AdminModel admin;

  const LoginResponseModel({required this.token, required this.admin});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Assumes the backend returns `{ "token": "...", "admin": {...} }`.
    // If your `competition-api` login response wraps things differently
    // (e.g. `accessToken`, or the admin fields flattened at the top
    // level instead of nested under `admin`), this is the one place to
    // adjust — nothing else in the auth feature needs to change.
    return LoginResponseModel(
      token: (json['token'] ?? json['accessToken']).toString(),
      admin: AdminModel.fromJson(json['admin'] as Map<String, dynamic>? ?? json),
    );
  }
}

/// Talks directly to `POST /api/admin/auth/login`. Throws
/// [ServerException]/[NetworkException]/[ValidationException]/
/// [UnauthorizedException] (via [DioClient]), which the repository
/// catches and converts to Failures.
abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<LoginResponseModel> login({required String email, required String password}) async {
    final response = await client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}
