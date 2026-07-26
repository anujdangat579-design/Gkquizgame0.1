import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_categories.dart';
import 'category_state.dart';

/// `ref.watch(categoryNotifierProvider)` gives the current
/// [CategoryState]; `ref.read(...notifier)` gives access to
/// [loadCategories]. Use case comes from get_it (`sl`) — same split as
/// `competitionNotifierProvider`.
final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(getCategories: sl());
});

class CategoryNotifier extends StateNotifier<CategoryState> {
  final GetCategories getCategories;

  CategoryNotifier({required this.getCategories}) : super(const CategoryState());

  Future<void> loadCategories() async {
    state = state.copyWith(viewState: CategoryViewState.loading, clearError: true);

    final result = await getCategories(const NoParams());

    result.fold(
      (failure) {
        AppLogger.warning('loadCategories failed: ${failure.message}', tag: 'Category');
        state = state.copyWith(viewState: CategoryViewState.error, errorMessage: failure.message);
      },
      (categories) {
        state = state.copyWith(
          viewState: CategoryViewState.loaded,
          categories: categories,
          clearError: true,
        );
      },
    );
  }
}
