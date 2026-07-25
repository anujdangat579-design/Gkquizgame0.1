import 'package:get_it/get_it.dart';

import '../data/datasources/profile_remote_data_source.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/get_badges.dart';
import '../domain/usecases/get_match_history.dart';
import '../domain/usecases/get_player_statistics.dart';
import '../domain/usecases/get_purchased_notes.dart';
import '../domain/usecases/get_transactions.dart';

/// Everything the `profile` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo) are already
/// registered — call `registerCoreDependencies(sl)` first. Same shape as
/// `account_injection.dart` / `competition_injection.dart`.
void registerProfileDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMatchHistory(sl()));
  sl.registerLazySingleton(() => GetPlayerStatistics(sl()));
  sl.registerLazySingleton(() => GetBadges(sl()));
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => GetPurchasedNotes(sl()));
}
