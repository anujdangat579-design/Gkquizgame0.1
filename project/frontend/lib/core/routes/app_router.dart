import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/routes/account_routes.dart';
import '../../features/admin/routes/admin_routes.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/competition/routes/competition_routes.dart';
import '../../features/dashboard/routes/dashboard_routes.dart';
import '../../features/study_notes/routes/study_notes_routes.dart';
import '../navigation/main_shell_page.dart';
import '../splash/splash_page.dart';

/// Composition point for routing. Each feature owns and exports its own
/// `List<RouteBase>`; this file only merges them into one GoRouter so
/// `main.dart` doesn't need to know feature internals. Adding a new
/// feature means adding one spread entry to `routes` below — or, if it
/// belongs in the bottom nav, one more `StatefulShellBranch` in
/// `_mainShellRoute`.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Pre-login flow — outside the bottom-nav shell on purpose, since
      // none of these screens have tabs to switch between.
      ...AuthRoutes.routes,
      // Study Notes — reached via push from the Dashboard's quick
      // actions, not its own bottom-nav tab, so (like auth) it lives
      // outside `_mainShellRoute` rather than as a fourth
      // `StatefulShellBranch`. `library` inside these routes reuses the
      // profile feature's `PurchasedNotesPage` — see
      // `StudyNotesRoutes`'s doc comment.
      ...StudyNotesRoutes.routes,
      // Competition Control Dashboard — pushed by an admin from a
      // specific competition (e.g. a "Manage live" action on
      // CompetitionDetailsPage/CompetitionCard); like Study Notes, it
      // has no tabs of its own so it lives outside `_mainShellRoute`.
      ...AdminRoutes.routes,
      _mainShellRoute,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  /// The authenticated app's bottom-nav shell. Each branch keeps its own
  /// navigation stack (see `MainShellPage`'s doc comment) — pushing the
  /// competition form and switching tabs doesn't lose that stack.
  ///
  /// `dashboard` and `competitions` reuse their feature's own route list
  /// so this doesn't duplicate what `DashboardRoutes` / `CompetitionRoutes`
  /// already own. `account` now does the same, reading a real profile via
  /// `features/account/`.
  static final StatefulShellRoute _mainShellRoute = StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => MainShellPage(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: DashboardRoutes.routes,
      ),
      StatefulShellBranch(
        routes: CompetitionRoutes.routes,
      ),
      StatefulShellBranch(
        routes: AccountRoutes.routes,
      ),
    ],
  );
}
