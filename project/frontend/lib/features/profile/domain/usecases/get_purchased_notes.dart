import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class GetPurchasedNotesParams extends Equatable {
  final int page;
  final int limit;

  const GetPurchasedNotesParams({
    this.page = AppConstants.defaultPage,
    this.limit = AppConstants.defaultPageLimit,
  });

  @override
  List<Object?> get props => [page, limit];
}

class GetPurchasedNotes implements UseCase<PurchasedNotesResult, GetPurchasedNotesParams> {
  final ProfileRepository repository;

  GetPurchasedNotes(this.repository);

  @override
  Future<Either<Failure, PurchasedNotesResult>> call(GetPurchasedNotesParams params) {
    return repository.getPurchasedNotes(page: params.page, limit: params.limit);
  }
}
