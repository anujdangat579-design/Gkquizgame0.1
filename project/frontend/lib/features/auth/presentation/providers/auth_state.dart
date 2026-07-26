import 'package:equatable/equatable.dart';

import '../../domain/entities/admin.dart';

enum AuthViewState { initial, loading, authenticated, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `CompetitionState`'s shape.
class AuthState extends Equatable {
  final AuthViewState viewState;
  final Admin? admin;
  final String? errorMessage;

  const AuthState({
    this.viewState = AuthViewState.initial,
    this.admin,
    this.errorMessage,
  });

  bool get isLoading => viewState == AuthViewState.loading;

  AuthState copyWith({
    AuthViewState? viewState,
    Admin? admin,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      viewState: viewState ?? this.viewState,
      admin: admin ?? this.admin,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, admin, errorMessage];
}
