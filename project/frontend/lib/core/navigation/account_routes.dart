import 'package:go_router/go_router.dart';

import 'placeholder_pages.dart';

/// Route path + GoRoute for the shell's "Account" tab. Kept here alongside
/// `placeholder_pages.dart` rather than as a full `features/account/`
/// feature — there's no domain/data layer to route around yet, just this
/// one path. Promote both into a real feature folder once account data
/// exists, mirroring `DashboardRoutes` / `CompetitionRoutes`.
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
