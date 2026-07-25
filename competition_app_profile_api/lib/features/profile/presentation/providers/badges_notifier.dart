import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_badges.dart';
import 'badges_state.dart';

final badgesNotifierProvider = StateNotifierProvider<BadgesNotifier, BadgesState>((ref) {
  return BadgesNotifier(getBadges: sl());
});

class BadgesNotifier extends StateNotifier<BadgesState> {
  final GetBadges getBadges;

  BadgesNotifier({required this.getBadges}) : super(const BadgesState());

  Future<void> loadBadges() async {
    state = state.copyWith(viewState: BadgesViewState.loading, clearError: true);

    final result = await getBadges(const NoParams());

    result.fold(
      (failure) {
        AppLogger.warning('loadBadges failed: ${failure.message}', tag: 'Profile');
        state = state.copyWith(viewState: BadgesViewState.error, errorMessage: failure.message);
      },
      (badges) {
        state = state.copyWith(viewState: BadgesViewState.loaded, badges: badges, clearError: true);
      },
    );
  }
}
