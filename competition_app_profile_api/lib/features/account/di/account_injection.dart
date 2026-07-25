import 'package:get_it/get_it.dart';

import '../data/datasources/account_remote_data_source.dart';
import '../data/repositories/account_repository_impl.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/usecases/get_profile.dart';
import '../domain/usecases/update_profile.dart';

/// Everything the `account` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo) are already
/// registered — call `registerCoreDependencies(sl)` first. Same shape as
/// `competition_injection.dart` / `auth_injection.dart`.
void registerAccountDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
}
