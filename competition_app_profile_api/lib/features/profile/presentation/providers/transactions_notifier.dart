import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import 'transactions_state.dart';

/// `ref.watch(transactionsNotifierProvider)` gives the current
/// [TransactionsState]; `ref.read(...notifier)` gives access to
/// [loadTransactions].
final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(getTransactions: sl());
});

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final GetTransactions getTransactions;

  TransactionsNotifier({required this.getTransactions}) : super(const TransactionsState());

  /// Fetches [page] for the given [type] filter (null = all types),
  /// replacing whatever list was previously loaded — mirrors
  /// `LeaderboardNotifier.loadLeaderboard`'s "switch the filter, expect a
  /// fresh fetch" behavior rather than filtering a fixed local list.
  Future<void> loadTransactions({
    int page = AppConstants.defaultPage,
    TransactionType? type,
  }) async {
    state = state.copyWith(
      viewState: TransactionsViewState.loading,
      typeFilter: type,
      clearTypeFilter: type == null,
      clearError: true,
    );

    final result = await getTransactions(GetTransactionsParams(page: page, type: type));

    result.fold(
      (failure) {
        AppLogger.warning('loadTransactions failed: ${failure.message}', tag: 'Profile');
        state = state.copyWith(viewState: TransactionsViewState.error, errorMessage: failure.message);
      },
      (data) {
        state = state.copyWith(
          viewState: TransactionsViewState.loaded,
          transactions: data.transactions,
          page: data.page,
          totalPages: data.totalPages,
          clearError: true,
        );
      },
    );
  }
}
