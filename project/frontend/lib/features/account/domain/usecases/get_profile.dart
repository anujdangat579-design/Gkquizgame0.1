import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/account_repository.dart';

class GetProfile implements UseCase<UserProfile, NoParams> {
  final AccountRepository repository;

  GetProfile(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(NoParams params) {
    return repository.getProfile();
  }
}
