import 'package:get_it/get_it.dart';

import '../data/datasources/matchmaking_remote_data_source.dart';
import '../data/repositories/matchmaking_repository_impl.dart';
import '../data/services/matchmaking_socket_service.dart';
import '../domain/repositories/matchmaking_repository.dart';
import '../domain/usecases/enter_matchmaking_queue.dart';
import '../domain/usecases/get_matchmaking_status.dart';
import '../domain/usecases/leave_matchmaking_queue.dart';

/// Everything the `matchmaking` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo, TokenStorage) are
/// already registered — call `registerCoreDependencies(sl)` first. Same
/// shape as `registerPaymentDependencies`.
///
/// `MatchmakingSocketService` rides along here too, even though it wraps
/// a socket connection rather than an HTTP data source — same
/// "infrastructure the presentation layer shouldn't construct itself"
/// reasoning as `CashfreeCheckoutService` in the payment feature's DI.
void registerMatchmakingDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<MatchmakingRemoteDataSource>(
    () => MatchmakingRemoteDataSourceImpl(sl()),
  );

  // Services
  sl.registerLazySingleton<MatchmakingSocketService>(
    () => MatchmakingSocketService(sl()),
  );

  // Repositories
  sl.registerLazySingleton<MatchmakingRepository>(
    () => MatchmakingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => EnterMatchmakingQueue(sl()));
  sl.registerLazySingleton(() => GetMatchmakingStatus(sl()));
  sl.registerLazySingleton(() => LeaveMatchmakingQueue(sl()));
}
