import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_note_categories.dart';
import 'note_category_state.dart';

final noteCategoryNotifierProvider =
    StateNotifierProvider<NoteCategoryNotifier, NoteCategoryState>((ref) {
  return NoteCategoryNotifier(getNoteCategories: sl());
});

class NoteCategoryNotifier extends StateNotifier<NoteCategoryState> {
  final GetNoteCategories getNoteCategories;

  NoteCategoryNotifier({required this.getNoteCategories}) : super(const NoteCategoryState());

  Future<void> loadCategories() async {
    state = state.copyWith(viewState: NoteCategoryViewState.loading, clearError: true);

    final result = await getNoteCategories(const NoParams());

    result.fold(
      (failure) {
        AppLogger.warning('loadNoteCategories failed: ${failure.message}', tag: 'StudyNotes');
        state = state.copyWith(viewState: NoteCategoryViewState.error, errorMessage: failure.message);
      },
      (categories) {
        state = state.copyWith(
          viewState: NoteCategoryViewState.loaded,
          categories: categories,
          clearError: true,
        );
      },
    );
  }
}
