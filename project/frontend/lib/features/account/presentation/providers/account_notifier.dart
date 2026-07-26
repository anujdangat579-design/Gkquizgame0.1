import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import 'account_state.dart';

/// `ref.watch(accountNotifierProvider)` gives the current [AccountState];
/// `ref.read(...notifier)` gives access to [loadProfile]/[updateProfile].
/// Use cases still come from get_it (`sl`) — same split as
/// `competitionNotifierProvider` / `authNotifierProvider`.
final accountNotifierProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(getProfile: sl(), updateProfile: sl());
});

class AccountNotifier extends StateNotifier<AccountState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;

  AccountNotifier({required this.getProfile, required this.updateProfile})
      : super(const AccountState());

  Future<void> loadProfile() async {
    state = state.copyWith(viewState: AccountViewState.loading, clearError: true);

    final result = await getProfile(const NoParams());

    result.fold(
      (failure) {
        AppLogger.warning('loadProfile failed: ${failure.message}', tag: 'Account');
        state = state.copyWith(viewState: AccountViewState.error, errorMessage: failure.message);
      },
      (profile) {
        state = state.copyWith(viewState: AccountViewState.loaded, profile: profile, clearError: true);
      },
    );
  }

  /// Called from `EditProfilePage` on submit — see that page's doc
  /// comment. Leaves `state.profile` untouched on failure so the form
  /// (and `AccountPage`, if the sheet is dismissed) keeps showing the
  /// last-known-good profile rather than blanking it out.
  Future<bool> editProfile({String? name, String? username, DateTime? dateOfBirth, String? gender}) async {
    final result = await updateProfile(
      UpdateProfileParams(name: name, username: username, dateOfBirth: dateOfBirth, gender: gender),
    );

    return result.fold(
      (failure) {
        AppLogger.warning('updateProfile failed: ${failure.message}', tag: 'Account');
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (profile) {
        state = state.copyWith(profile: profile, clearError: true);
        return true;
      },
    );
  }
}
