import 'package:equatable/equatable.dart';

import '../../domain/entities/player_badge.dart';

enum BadgesViewState { initial, loading, loaded, error }

/// Mirrors `LeaderboardState`'s shape — a single loaded snapshot of the
/// player's full badge catalog (earned + locked), reloaded from scratch.
class BadgesState extends Equatable {
  final BadgesViewState viewState;
  final List<PlayerBadge> badges;
  final String? errorMessage;

  const BadgesState({
    this.viewState = BadgesViewState.initial,
    this.badges = const [],
    this.errorMessage,
  });

  BadgesState copyWith({
    BadgesViewState? viewState,
    List<PlayerBadge>? badges,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BadgesState(
      viewState: viewState ?? this.viewState,
      badges: badges ?? this.badges,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, badges, errorMessage];
}
