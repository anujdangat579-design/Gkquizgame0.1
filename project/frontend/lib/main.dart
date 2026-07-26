import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/logging/app_logger.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.info(
      'Starting up: environment=${EnvConfig.environment.name} '
      'apiBaseUrl=${EnvConfig.apiBaseUrl}',
      tag: 'Startup',
    );

    // Widget build/layout/paint errors: Flutter normally just prints these
    // in red to the console and moves on. Route them through AppLogger
    // too so they show up wherever the rest of the app's logs do (and
    // aren't silently lost in a release build with no console attached).
    FlutterError.onError = (details) {
      AppLogger.error(
        details.exceptionAsString(),
        tag: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    await di.initDependencies();
    runApp(const ProviderScope(child: CompetitionApp()));
  }, (error, stackTrace) {
    // Anything async that escapes a try/catch (a bad Future, a stream
    // error, etc.) ends up here instead of crashing silently.
    AppLogger.error('Uncaught error', tag: 'Zone', error: error, stackTrace: stackTrace);
  });
}
