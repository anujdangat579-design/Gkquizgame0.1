import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

/// Concrete implementation the DI container binds to [AccountRepository].
/// Checks connectivity, calls the remote data source, and converts any
/// thrown exception into a typed [Failure] — same `_guard` shape as
/// `CompetitionRepositoryImpl`.
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AccountRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, UserProfile>> getProfile() {
    return _guard(() => remoteDataSource.getProfile());
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile({
    String? name,
    String? username,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    return _guard(() => remoteDataSource.updateProfile(
          name: name,
          username: username,
          dateOfBirth: dateOfBirth,
          gender: gender,
        ));
  }

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
