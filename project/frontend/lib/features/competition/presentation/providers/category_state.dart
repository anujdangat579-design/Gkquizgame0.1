import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

enum CategoryViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Mirrors
/// `CompetitionState`'s shape.
class CategoryState extends Equatable {
  final CategoryViewState viewState;
  final List<Category> categories;
  final String? errorMessage;

  const CategoryState({
    this.viewState = CategoryViewState.initial,
    this.categories = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    CategoryViewState? viewState,
    List<Category>? categories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryState(
      viewState: viewState ?? this.viewState,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, categories, errorMessage];
}
