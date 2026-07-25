import 'package:flutter/material.dart';

import 'core/config/env_config.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget. `main.dart` only bootstraps (error handling, DI, then
/// `runApp`) — everything about what the app actually looks like
/// (theming, routing, the env banner) lives here instead.
class CompetitionApp extends StatelessWidget {
  const CompetitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        // A build pointed anywhere but prod should be unmistakable,
        // including in a release build handed to a tester.
        if (EnvConfig.isProd || child == null) return child ?? const SizedBox.shrink();
        return Banner(
          message: EnvConfig.environment.name.toUpperCase(),
          location: BannerLocation.topEnd,
          color: EnvConfig.isStaging ? Colors.orange : Colors.blue,
          child: child,
        );
      },
    );
  }
}
