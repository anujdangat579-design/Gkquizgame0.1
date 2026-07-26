import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_user.dart';
import '../repositories/user_repository.dart';

class UpdateUserParams extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? phone;

  const UpdateUserParams({
    required this.id,
    this.name,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, email, phone];
}

class UpdateUser implements UseCase<AdminUser, UpdateUserParams> {
  final UserRepository repository;

  UpdateUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(UpdateUserParams params) {
    return repository.updateUser(
      id: params.id,
      name: params.name,
      email: params.email,
      phone: params.phone,
    );
  }
}
