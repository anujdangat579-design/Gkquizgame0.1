import 'package:get_it/get_it.dart';

import '../data/services/competition_control_socket_service.dart';

/// Registers the `admin` feature's dependencies. Currently just the
/// Competition Control Dashboard's socket wrapper — mirrors
/// `registerMatchmakingDependencies`'s "socket service as
/// infrastructure the presentation layer shouldn't construct itself"
/// reasoning. Assumes `registerCoreDependencies(sl)` (for `TokenStorage`)
/// has already run.
///
/// TODO(backend): once the admin control REST endpoints are confirmed
/// (see TODOs in `CompetitionControlNotifier`), add this feature's
/// remote data source / repository / use cases here too, the same way
/// `registerMatchmakingDependencies` does.
void registerAdminDependencies(GetIt sl) {
  sl.registerLazySingleton<CompetitionControlSocketService>(
    () => CompetitionControlSocketService(sl()),
  );
}
