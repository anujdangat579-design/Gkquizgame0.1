import 'package:get_it/get_it.dart';

import '../data/datasources/user_remote_data_source.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/usecases/create_user.dart';
import '../domain/usecases/delete_user.dart';
import '../domain/usecases/get_user_by_id.dart';
import '../domain/usecases/get_users.dart';
import '../domain/usecases/set_user_status.dart';
import '../domain/usecases/update_user.dart';

/// Everything the `users` feature needs, registered in one place.
/// Assumes core dependencies (DioClient, NetworkInfo) are already
/// registered — call `registerCoreDependencies(sl)` first. Same shape
/// as `registerCompetitionDependencies`.
void registerUsersDependencies(GetIt sl) {
  // Data source
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUsers(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));
  sl.registerLazySingleton(() => CreateUser(sl()));
  sl.registerLazySingleton(() => UpdateUser(sl()));
  sl.registerLazySingleton(() => SetUserStatus(sl()));
  sl.registerLazySingleton(() => DeleteUser(sl()));
}
