import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_user.dart';
import '../repositories/user_repository.dart';

class SetUserStatusParams extends Equatable {
  final String id;
  final bool active;

  const SetUserStatusParams({required this.id, required this.active});

  @override
  List<Object?> get props => [id, active];
}

/// Blocks/unblocks a player account. Mirrors `SetCompetitionStatus`'s
/// shape — a single toggle use case rather than separate
/// Block/Unblock classes, since it's the same action with an inverted
/// argument either way.
class SetUserStatus implements UseCase<AdminUser, SetUserStatusParams> {
  final UserRepository repository;

  SetUserStatus(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(SetUserStatusParams params) {
    return repository.setUserStatus(id: params.id, active: params.active);
  }
}
