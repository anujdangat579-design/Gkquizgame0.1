import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_statistics.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (DashboardRepositoryImpl); the presentation
/// layer never talks to it directly, only through use cases.
abstract class DashboardRepository {
  Future<Either<Failure, DashboardStatistics>> getStatistics();
}
