import 'package:get_it/get_it.dart';

import 'core/di/core_injection.dart';
import 'features/account/di/account_injection.dart';
import 'features/admin/di/admin_injection.dart';
import 'features/auth/di/auth_injection.dart';
import 'features/competition/di/competition_injection.dart';
import 'features/dashboard/di/dashboard_injection.dart';
import 'features/matchmaking/di/matchmaking_injection.dart';
import 'features/payment/di/payment_injection.dart';
import 'features/profile/di/profile_injection.dart';
import 'features/questions/di/questions_injection.dart';
import 'features/study_notes/di/study_notes_injection.dart';
import 'features/users/di/users_injection.dart';

final sl = GetIt.instance; // service locator

/// Composition root. Order matters: core first (every feature depends on
/// it), then each feature registers itself independently. To add a new
/// feature: create `<feature>/di/<feature>_injection.dart` following the
/// same pattern as competition's, then add one line here.
///
/// `registerStudyNotesDependencies` must come after
/// `registerPaymentDependencies` since its buy flow resolves
/// `CashfreeCheckoutService` (registered by the payment feature) via `sl()`.
Future<void> initDependencies() async {
  registerCoreDependencies(sl);
  registerAuthDependencies(sl);
  registerAccountDependencies(sl);
  registerAdminDependencies(sl);
  registerCompetitionDependencies(sl);
  registerUsersDependencies(sl);
  registerQuestionsDependencies(sl);
  registerDashboardDependencies(sl);
  registerPaymentDependencies(sl);
  registerMatchmakingDependencies(sl);
  registerProfileDependencies(sl);
  registerStudyNotesDependencies(sl);
}
