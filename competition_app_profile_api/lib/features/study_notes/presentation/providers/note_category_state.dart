import 'package:equatable/equatable.dart';

import '../../domain/entities/note_category.dart';

enum NoteCategoryViewState { initial, loading, loaded, error }

/// Mirrors `CategoryState`'s shape.
class NoteCategoryState extends Equatable {
  final NoteCategoryViewState viewState;
  final List<NoteCategory> categories;
  final String? errorMessage;

  const NoteCategoryState({
    this.viewState = NoteCategoryViewState.initial,
    this.categories = const [],
    this.errorMessage,
  });

  NoteCategoryState copyWith({
    NoteCategoryViewState? viewState,
    List<NoteCategory>? categories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NoteCategoryState(
      viewState: viewState ?? this.viewState,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [viewState, categories, errorMessage];
}
