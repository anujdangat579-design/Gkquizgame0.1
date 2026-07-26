import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin.dart';

/// Result of a successful login — the token is what `DioClient` attaches
/// to every subsequent request (once the caller saves it to
/// `TokenStorage`); `admin` is just for display (e.g. a greeting/avatar).
class LoginResult {
  final String token;
  final Admin admin;

  const LoginResult({required this.token, required this.admin});
}

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (AuthRepositoryImpl); the presentation layer
/// never talks to it directly, only through use cases. Mirrors
/// CompetitionRepository's shape.
abstract class AuthRepository {
  Future<Either<Failure, LoginResult>> login({
    required String email,
    required String password,
  });

  /// Clears the locally stored token. There's no server-side "invalidate
  /// this session" call in scope yet — this is a local-only logout.
  Future<void> logout();
}
