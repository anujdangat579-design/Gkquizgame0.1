import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dashboard_statistics.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatistics implements UseCase<DashboardStatistics, NoParams> {
  final DashboardRepository repository;

  GetDashboardStatistics(this.repository);

  @override
  Future<Either<Failure, DashboardStatistics>> call(NoParams params) {
    return repository.getStatistics();
  }
}
