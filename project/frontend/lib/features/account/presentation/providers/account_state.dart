import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

enum AccountViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `CompetitionState`'s shape.
class AccountState extends Equatable {
  final AccountViewState viewState;
  final UserProfile? profile;
  final String? errorMessage;

  const AccountState({
    this.viewState = AccountViewState.initial,
    this.profile,
    this.errorMessage,
  });

  AccountState copyWith({
    AccountViewState? viewState,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountState(
      viewState: viewState ?? this.viewState,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, profile, errorMessage];
}
