import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_competition_details.dart';
import 'competition_details_state.dart';

/// Keyed by competition id via `.family` (unlike `competitionNotifierProvider`
/// / `liveCompetitionNotifierProvider`, which each back a single list) so
/// viewing two different competitions' details in the same session
/// doesn't share state, and `.autoDispose` so a stale fetch isn't kept
/// around once the details screen for that id is popped.
///
/// `ref.watch(competitionDetailsNotifierProvider(id))` gives the current
/// [CompetitionDetailsState]; `ref.read(...notifier)` gives access to
/// [loadDetails].
final competitionDetailsNotifierProvider = StateNotifierProvider.autoDispose
    .family<CompetitionDetailsNotifier, CompetitionDetailsState, String>((ref, id) {
  return CompetitionDetailsNotifier(getCompetitionDetails: sl(), id: id);
});

class CompetitionDetailsNotifier extends StateNotifier<CompetitionDetailsState> {
  final GetCompetitionDetails getCompetitionDetails;
  final String id;

  CompetitionDetailsNotifier({required this.getCompetitionDetails, required this.id})
      : super(const CompetitionDetailsState());

  Future<void> loadDetails() async {
    state = state.copyWith(viewState: CompetitionDetailsViewState.loading, clearError: true);

    final result = await getCompetitionDetails(id);

    result.fold(
      (failure) {
        AppLogger.warning('loadDetails($id) failed: ${failure.message}', tag: 'CompetitionDetails');
        state = state.copyWith(viewState: CompetitionDetailsViewState.error, errorMessage: failure.message);
      },
      (details) {
        state = state.copyWith(
          viewState: CompetitionDetailsViewState.loaded,
          details: details,
          clearError: true,
        );
      },
    );
  }
}
