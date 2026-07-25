import 'package:go_router/go_router.dart';

import '../presentation/pages/account_page.dart';

/// Route path + GoRoute for the shell's "Account" tab, following the
/// same per-feature pattern as `competition/routes/competition_routes.dart`.
/// Promoted out of `core/navigation/` now that this feature has a real
/// domain/data layer behind it — same move `DashboardRoutes` /
/// `CompetitionRoutes` already made.
class AccountRoutes {
  AccountRoutes._();

  static const String home = '/account';

  static List<RouteBase> get routes => [
        GoRoute(
          path: home,
          name: 'account',
          builder: (context, state) => const AccountPage(),
        ),
      ];
}
