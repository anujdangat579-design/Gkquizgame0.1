import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_user.dart';
import '../repositories/user_repository.dart';

class CreateUserParams extends Equatable {
  final String name;
  final String email;
  final String? phone;
  final String? password;

  const CreateUserParams({
    required this.name,
    required this.email,
    this.phone,
    this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class CreateUser implements UseCase<AdminUser, CreateUserParams> {
  final UserRepository repository;

  CreateUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(CreateUserParams params) {
    return repository.createUser(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
    );
  }
}
