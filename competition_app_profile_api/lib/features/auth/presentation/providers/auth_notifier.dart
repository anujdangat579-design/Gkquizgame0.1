import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import 'auth_state.dart';

/// `ref.watch(authNotifierProvider)` gives the current [AuthState];
/// `ref.read(...notifier)` gives access to [login]/[logout]. Use cases
/// still come from get_it (`sl`) — same split as `competitionNotifierProvider`.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(login: sl(), logout: sl());
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Login login;
  final Logout logout;

  AuthNotifier({required this.login, required this.logout}) : super(const AuthState());

  /// Returns true on success so the page can navigate; false leaves the
  /// error in `state.errorMessage` for the page to display.
  Future<bool> loginWithPassword({required String email, required String password}) async {
    state = state.copyWith(viewState: AuthViewState.loading, clearError: true);

    final result = await login(LoginParams(email: email, password: password));

    return result.fold(
      (failure) {
        AppLogger.warning('login failed: ${failure.message}', tag: 'Auth');
        state = state.copyWith(viewState: AuthViewState.error, errorMessage: failure.message);
        return false;
      },
      (loginResult) {
        state = state.copyWith(viewState: AuthViewState.authenticated, admin: loginResult.admin);
        return true;
      },
    );
  }

  Future<void> logOut() async {
    await logout();
    state = const AuthState();
  }
}
