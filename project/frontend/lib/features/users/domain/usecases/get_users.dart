import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

class GetUsersParams extends Equatable {
  final int page;
  final int limit;
  final String? search;

  const GetUsersParams({
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
    this.search,
  });

  @override
  List<Object?> get props => [page, limit, search];
}

class GetUsers implements UseCase<UserListResult, GetUsersParams> {
  final UserRepository repository;

  GetUsers(this.repository);

  @override
  Future<Either<Failure, UserListResult>> call(GetUsersParams params) {
    return repository.getUsers(page: params.page, limit: params.limit, search: params.search);
  }
}
