import 'package:go_router/go_router.dart';

import '../presentation/pages/dashboard_page.dart';

/// Route paths + GoRoute definitions owned by this feature, following the
/// same per-feature pattern as `competition/routes/competition_routes.dart`.
class DashboardRoutes {
  DashboardRoutes._();

  static const String home = '/dashboard';

  static List<RouteBase> get routes => [
        GoRoute(
          path: home,
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
      ];
}
