import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_user.dart';

class UserListResult {
  final List<AdminUser> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const UserListResult({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (UserRepositoryImpl); the presentation layer
/// never talks to it directly, only through use cases. Mirrors
/// `CompetitionRepository`'s shape.
abstract class UserRepository {
  Future<Either<Failure, UserListResult>> getUsers({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? search,
  });

  Future<Either<Failure, AdminUser>> getUserById(String id);

  Future<Either<Failure, AdminUser>> createUser({
    required String name,
    required String email,
    String? phone,
    String? password,
  });

  Future<Either<Failure, AdminUser>> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
  });

  Future<Either<Failure, AdminUser>> setUserStatus({
    required String id,
    required bool active,
  });

  Future<Either<Failure, void>> deleteUser(String id);
}
