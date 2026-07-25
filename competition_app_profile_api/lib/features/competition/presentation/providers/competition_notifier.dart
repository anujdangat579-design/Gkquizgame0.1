import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/competition.dart';
import '../../domain/usecases/create_competition.dart';
import '../../domain/usecases/delete_competition.dart';
import '../../domain/usecases/get_competitions.dart';
import '../../domain/usecases/set_competition_status.dart';
import '../../domain/usecases/update_competition.dart';
import 'competition_state.dart';

/// The widget-facing provider. `ref.watch(competitionNotifierProvider)`
/// gives the current [CompetitionState]; `ref.read(...notifier)` gives
/// access to the methods below to trigger actions.
///
/// Use cases still come from get_it (`sl`) — Riverpod owns state, get_it
/// keeps owning wiring for data/domain, so nothing in competition_injection.dart
/// had to change.
final competitionNotifierProvider =
    StateNotifierProvider<CompetitionNotifier, CompetitionState>((ref) {
  return CompetitionNotifier(
    getCompetitions: sl(),
    createCompetition: sl(),
    updateCompetition: sl(),
    setCompetitionStatus: sl(),
    deleteCompetition: sl(),
  );
});

class CompetitionNotifier extends StateNotifier<CompetitionState> {
  final GetCompetitions getCompetitions;
  final CreateCompetition createCompetition;
  final UpdateCompetition updateCompetition;
  final SetCompetitionStatus setCompetitionStatus;
  final DeleteCompetition deleteCompetition;

  CompetitionNotifier({
    required this.getCompetitions,
    required this.createCompetition,
    required this.updateCompetition,
    required this.setCompetitionStatus,
    required this.deleteCompetition,
  }) : super(const CompetitionState());

  Future<void> loadCompetitions({int page = AppConstants.defaultPage, String? search}) async {
    state = state.copyWith(viewState: ViewState.loading);

    final result = await getCompetitions(GetCompetitionsParams(page: page, search: search));

    result.fold(
      (failure) {
        AppLogger.warning('loadCompetitions failed: ${failure.message}', tag: 'Competition');
        state = state.copyWith(viewState: ViewState.error, errorMessage: failure.message);
      },
      (data) {
        state = state.copyWith(
          viewState: ViewState.loaded,
          competitions: data.competitions,
          page: data.page,
          totalPages: data.totalPages,
          clearError: true,
        );
      },
    );
  }

  Future<bool> create({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _mutate(() => createCompetition(CreateCompetitionParams(
          name: name,
          description: description,
          startDate: startDate,
          endDate: endDate,
        )));
  }

  Future<bool> update({
    required String id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _mutate(() => updateCompetition(UpdateCompetitionParams(
          id: id,
          name: name,
          description: description,
          startDate: startDate,
          endDate: endDate,
        )));
  }

  Future<bool> toggleStatus(Competition competition) {
    return _mutate(() => setCompetitionStatus(
          SetCompetitionStatusParams(id: competition.id, enabled: !competition.isEnabled),
        ));
  }

  Future<bool> remove(String id) async {
    state = state.copyWith(isMutating: true);

    final result = await deleteCompetition(id);

    return result.fold(
      (failure) {
        AppLogger.warning('remove($id) failed: ${failure.message}', tag: 'Competition');
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          isMutating: false,
          competitions: state.competitions.where((c) => c.id != id).toList(),
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> _mutate(Future<dynamic> Function() action) async {
    state = state.copyWith(isMutating: true);

    final result = await action();

    return result.fold(
      (failure) {
        AppLogger.warning('Mutation failed: ${failure.message}', tag: 'Competition');
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return false;
      },
      (competition) {
        final Competition typed = competition as Competition;
        final competitions = [...state.competitions];
        final index = competitions.indexWhere((c) => c.id == typed.id);
        if (index >= 0) {
          competitions[index] = typed;
        } else {
          competitions.insert(0, typed);
        }
        state = state.copyWith(isMutating: false, competitions: competitions, clearError: true);
        return true;
      },
    );
  }
}
