import 'package:get_it/get_it.dart';

import '../data/datasources/dashboard_remote_data_source.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/usecases/get_dashboard_statistics.dart';

/// Everything the `dashboard` feature's statistics API needs, registered
/// in one place. Assumes core dependencies (DioClient, NetworkInfo) are
/// already registered — call `registerCoreDependencies(sl)` first. Same
/// shape as `registerCompetitionDependencies`.
///
/// Consumed by `dashboardStatisticsNotifierProvider`
/// (`presentation/providers/dashboard_statistics_notifier.dart`), which
/// `DashboardPage` reads for its stat cards instead of counting a single
/// loaded page of competitions client-side.
void registerDashboardDependencies(GetIt sl) {
  // Data source
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use case
  sl.registerLazySingleton(() => GetDashboardStatistics(sl()));
}
