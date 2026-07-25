import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_user.dart';
import '../repositories/user_repository.dart';

class GetUserById implements UseCase<AdminUser, String> {
  final UserRepository repository;

  GetUserById(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(String id) {
    return repository.getUserById(id);
  }
}
