import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (AccountRepositoryImpl); the presentation
/// layer never talks to it directly, only through use cases. Mirrors
/// CompetitionRepository's / AuthRepository's shape.
abstract class AccountRepository {
  Future<Either<Failure, UserProfile>> getProfile();

  /// Wired into `EditProfilePage`, pushed from `AccountPage`'s edit
  /// action — mirrors how `CompetitionRepository` exposes create/update
  /// behind a single contract.
  Future<Either<Failure, UserProfile>> updateProfile({
    String? name,
    String? username,
    DateTime? dateOfBirth,
    String? gender,
  });
}
