import 'package:go_router/go_router.dart';

import '../presentation/pages/competition_control_dashboard_page.dart';

/// Route paths + GoRoute definitions owned by the `admin` feature.
/// Lives outside the bottom-nav shell (like `AuthRoutes`/`StudyNotesRoutes`)
/// since the control dashboard is reached by pushing from a specific
/// competition, not its own tab — merged into the app router the same
/// way, via a spread entry in `core/routes/app_router.dart`.
class AdminRoutes {
  AdminRoutes._();

  static const String control = '/admin/competitions/:id/control';

  static String controlPath(String competitionId) => '/admin/competitions/$competitionId/control';

  static List<RouteBase> get routes => [
        GoRoute(
          path: control,
          name: 'competitionControlDashboard',
          builder: (context, state) => CompetitionControlDashboardPage(
            competitionId: state.pathParameters['id']!,
          ),
        ),
      ];
}
