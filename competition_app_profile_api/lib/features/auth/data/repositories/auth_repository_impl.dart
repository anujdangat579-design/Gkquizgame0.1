import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/admin.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Concrete implementation the DI container binds to [AuthRepository].
/// Owns the "session" concept end to end: on a successful login it
/// persists the token via [TokenStorage] before returning, so callers
/// (the notifier) never have to remember that step themselves; on
/// logout it clears it the same way.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LoginResult>> login({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await remoteDataSource.login(email: email, password: password);
      await tokenStorage.saveToken(response.token);
      final Admin admin = response.admin;
      return Right(LoginResult(token: response.token, admin: admin));
    } on UnauthorizedException catch (e) {
      // 401/403 on login itself means "wrong credentials", not "session
      // expired" — but DioClient maps both to UnauthorizedException, and
      // the message from the backend (e.g. "Invalid email or password")
      // is what should reach the form either way.
      return Left(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() => tokenStorage.clearToken();
}
