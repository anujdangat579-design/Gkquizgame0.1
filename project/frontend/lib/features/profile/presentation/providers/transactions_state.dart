import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/wallet_transaction.dart';

enum TransactionsViewState { initial, loading, loaded, error }

/// Mirrors `MatchHistoryState`'s shape — a single loaded page, replaced
/// on reload/pull-to-refresh or when [typeFilter] changes.
class TransactionsState extends Equatable {
  final TransactionsViewState viewState;
  final List<WalletTransaction> transactions;
  final TransactionType? typeFilter;
  final String? errorMessage;
  final int page;
  final int totalPages;

  const TransactionsState({
    this.viewState = TransactionsViewState.initial,
    this.transactions = const [],
    this.typeFilter,
    this.errorMessage,
    this.page = AppConstants.defaultPage,
    this.totalPages = 1,
  });

  TransactionsState copyWith({
    TransactionsViewState? viewState,
    List<WalletTransaction>? transactions,
    TransactionType? typeFilter,
    bool clearTypeFilter = false,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? totalPages,
  }) {
    return TransactionsState(
      viewState: viewState ?? this.viewState,
      transactions: transactions ?? this.transactions,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props =>
      [viewState, transactions, typeFilter, errorMessage, page, totalPages];
}
