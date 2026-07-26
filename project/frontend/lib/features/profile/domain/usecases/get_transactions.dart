import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wallet_transaction.dart';
import '../repositories/profile_repository.dart';

class GetTransactionsParams extends Equatable {
  final int page;
  final int limit;
  final TransactionType? type;

  const GetTransactionsParams({
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
    this.type,
  });

  @override
  List<Object?> get props => [page, limit, type];
}

class GetTransactions implements UseCase<TransactionsResult, GetTransactionsParams> {
  final ProfileRepository repository;

  GetTransactions(this.repository);

  @override
  Future<Either<Failure, TransactionsResult>> call(GetTransactionsParams params) {
    return repository.getTransactions(page: params.page, limit: params.limit, type: params.type);
  }
}
