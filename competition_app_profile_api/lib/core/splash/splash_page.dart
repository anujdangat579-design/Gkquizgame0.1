import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/routes/auth_routes.dart';
import '../../features/competition/routes/competition_routes.dart';
import '../../injection_container.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import '../theme/app_spacing.dart';

/// First screen shown on launch. `main.dart` already awaits
/// `di.initDependencies()` before `runApp`, so there's no async gap to
/// fill here today — this exists for two reasons instead:
///
///  1. A blank frame between process start and the first real screen
///     reads as a stutter; a branded screen with a minimum display time
///     reads as intentional.
///  2. It's the natural place for the startup check below: is there a
///     saved admin token? If so, skip straight past login. The token's
///     mere presence is checked here (no "is it still valid" call) —
///     an expired/invalid token still gets past this screen but then
///     gets a 401 on the first real request, which `DioClient` already
///     turns into an `UnauthorizedFailure` for that screen to handle.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  static const _minimumDisplayTime = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scale = Tween(begin: 0.92, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _proceedWhenReady();
  }

  Future<void> _proceedWhenReady() async {
    // `Future.wait` so a slow check doesn't feel abrupt and a fast one
    // doesn't feel rushed; the screen is up for at least
    // `_minimumDisplayTime` either way.
    final results = await Future.wait([
      Future<void>.delayed(_minimumDisplayTime),
      sl<TokenStorage>().getToken(),
    ]);
    if (!mounted) return;
    final token = results[1] as String?;
    context.go(token != null && token.isNotEmpty ? CompetitionRoutes.list : AuthRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Soft radial glow anchored behind the mark, seeded from the
          // brand color. Subtle on purpose — this is an admin tool, not
          // a marketing splash, so it reads as "polished" rather than
          // "decorative".
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    colorScheme.primary.withOpacity(0.06),
                    colorScheme.surface.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        size: 44,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(AppConstants.appName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage competitions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
