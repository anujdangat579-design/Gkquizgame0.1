import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/competition.dart';

enum ViewState { initial, loading, loaded, error }

/// Immutable state Riverpod's StateNotifier emits. Widgets rebuild only
/// when `copyWith` produces a genuinely different value (Equatable).
class CompetitionState extends Equatable {
  final ViewState viewState;
  final List<Competition> competitions;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool isMutating;

  const CompetitionState({
    this.viewState = ViewState.initial,
    this.competitions = const [],
    this.errorMessage,
    this.page = AppConstants.defaultPage,
    this.totalPages = 1,
    this.isMutating = false,
  });

  CompetitionState copyWith({
    ViewState? viewState,
    List<Competition>? competitions,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? totalPages,
    bool? isMutating,
  }) {
    return CompetitionState(
      viewState: viewState ?? this.viewState,
      competitions: competitions ?? this.competitions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [viewState, competitions, errorMessage, page, totalPages, isMutating];
}
