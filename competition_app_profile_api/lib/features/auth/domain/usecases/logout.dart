import '../repositories/auth_repository.dart';

/// Not a [UseCase] (no Failure to surface — clearing local storage
/// doesn't fail in a way the UI needs to react to), so it's a plain
/// class rather than implementing the `Either<Failure, T>` contract.
class Logout {
  final AuthRepository repository;

  Logout(this.repository);

  Future<void> call() => repository.logout();
}
