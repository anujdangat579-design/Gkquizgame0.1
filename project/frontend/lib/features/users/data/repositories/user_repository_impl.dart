import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';

/// Concrete implementation the DI container binds to [UserRepository].
/// Checks connectivity, calls the remote data source, and converts any
/// thrown exception into a typed [Failure] via Dartz's Either. Mirrors
/// `CompetitionRepositoryImpl`'s shape/conventions.
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, UserListResult>> getUsers({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? search,
  }) {
    return _guard(() async {
      final page_ = await remoteDataSource.getUsers(page: page, limit: limit, search: search);
      return UserListResult(
        users: page_.users,
        page: page_.page,
        limit: page_.limit,
        total: page_.total,
        totalPages: page_.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, AdminUser>> getUserById(String id) {
    return _guard(() => remoteDataSource.getUserById(id));
  }

  @override
  Future<Either<Failure, AdminUser>> createUser({
    required String name,
    required String email,
    String? phone,
    String? password,
  }) {
    return _guard(() => remoteDataSource.createUser(
          name: name,
          email: email,
          phone: phone,
          password: password,
        ));
  }

  @override
  Future<Either<Failure, AdminUser>> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
  }) {
    return _guard(() => remoteDataSource.updateUser(id: id, name: name, email: email, phone: phone));
  }

  @override
  Future<Either<Failure, AdminUser>> setUserStatus({
    required String id,
    required bool active,
  }) {
    return _guard(() => remoteDataSource.setStatus(id: id, active: active));
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) {
    return _guard(() => remoteDataSource.deleteUser(id));
  }

  /// Shared "check connectivity, run the call, map exceptions" wrapper —
  /// identical to `CompetitionRepositoryImpl._guard`.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await action();
      return Right(result);
    } on UnauthorizedException catch (e) {
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
}
