import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's main bottom-navigation scaffold.
///
/// Wraps a [StatefulNavigationShell] (see `AppRouter`'s
/// `StatefulShellRoute.indexedStack`) so each tab keeps its own
/// navigation stack — pushing a detail screen inside "Competitions" and
/// switching to "Account" and back preserves where you were, instead of
/// resetting to that tab's root the way a plain `IndexedStack` +
/// `BottomNavigationBar` built outside go_router would.
///
/// Tabs here are the destinations that make sense once a user is
/// authenticated and has completed their profile — this shell is not
/// part of the pre-login flow (splash/login/register/OTP/complete
/// profile all live outside it in `AppRouter`).
class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({super.key, required this.navigationShell});

  static const List<_Destination> _destinations = [
    _Destination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _Destination(
      label: 'Competitions',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events,
    ),
    _Destination(
      label: 'Account',
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // `initialLocation: true` when re-tapping the already-active tab pops
    // that tab's stack back to its root, matching the standard "tap the
    // active tab to go home" convention (Instagram, Gmail, etc.) instead
    // of leaving a stale detail screen showing.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
