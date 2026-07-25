import 'package:go_router/go_router.dart';

import '../presentation/pages/complete_profile_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/otp_verification_page.dart';
import '../presentation/pages/register_page.dart';

/// Route paths + GoRoute definitions owned by the auth feature, following
/// the same per-feature pattern as `competition/routes/competition_routes.dart`.
///
/// `login` is real (backed by `authNotifierProvider` -> `Login` use case)
/// and `SplashPage` now routes here when there's no saved admin token.
/// `register`/`otpVerification`/`completeProfile` are still UI-only —
/// the same "wire up a data/domain layer" step this feature's `login`
/// just went through would apply to each of those next.
class AuthRoutes {
  AuthRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String completeProfile = '/complete-profile';

  static List<RouteBase> get routes => [
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: otpVerification,
          name: 'otpVerification',
          // Destination (phone/email) is passed as `extra` from whatever
          // screen triggers OTP verification (e.g. register). Falls back
          // to the page's own default copy if none is supplied.
          builder: (context, state) => OtpVerificationPage(
            destination: state.extra as String? ?? 'your registered contact',
          ),
        ),
        GoRoute(
          path: completeProfile,
          name: 'completeProfile',
          builder: (context, state) => const CompleteProfilePage(),
        ),
      ];
}
