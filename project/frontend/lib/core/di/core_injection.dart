import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../storage/token_storage.dart';

/// Registers dependencies that every feature can rely on: connectivity,
/// network info, secure token storage, and the shared Dio client.
/// Nothing feature-specific belongs here — each feature registers its
/// own in `<feature>/di/`.
void registerCoreDependencies(GetIt sl) {
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<TokenStorage>(() => SecureTokenStorage.create());
  sl.registerLazySingleton<DioClient>(() => DioClient.create(sl()));
}
