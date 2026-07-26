import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/account_repository.dart';

class UpdateProfileParams extends Equatable {
  final String? name;
  final String? username;
  final DateTime? dateOfBirth;
  final String? gender;

  const UpdateProfileParams({this.name, this.username, this.dateOfBirth, this.gender});

  @override
  List<Object?> get props => [name, username, dateOfBirth, gender];
}

class UpdateProfile implements UseCase<UserProfile, UpdateProfileParams> {
  final AccountRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      name: params.name,
      username: params.username,
      dateOfBirth: params.dateOfBirth,
      gender: params.gender,
    );
  }
}
