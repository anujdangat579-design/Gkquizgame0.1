import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_purchased_notes.dart';
import 'purchased_notes_state.dart';

final purchasedNotesNotifierProvider =
    StateNotifierProvider<PurchasedNotesNotifier, PurchasedNotesState>((ref) {
  return PurchasedNotesNotifier(getPurchasedNotes: sl());
});

class PurchasedNotesNotifier extends StateNotifier<PurchasedNotesState> {
  final GetPurchasedNotes getPurchasedNotes;

  PurchasedNotesNotifier({required this.getPurchasedNotes}) : super(const PurchasedNotesState());

  Future<void> loadPurchasedNotes({int page = AppConstants.defaultPage}) async {
    state = state.copyWith(viewState: PurchasedNotesViewState.loading, clearError: true);

    final result = await getPurchasedNotes(GetPurchasedNotesParams(page: page));

    result.fold(
      (failure) {
        AppLogger.warning('loadPurchasedNotes failed: ${failure.message}', tag: 'Profile');
        state = state.copyWith(viewState: PurchasedNotesViewState.error, errorMessage: failure.message);
      },
      (data) {
        state = state.copyWith(
          viewState: PurchasedNotesViewState.loaded,
          notes: data.notes,
          page: data.page,
          totalPages: data.totalPages,
          clearError: true,
        );
      },
    );
  }
}
