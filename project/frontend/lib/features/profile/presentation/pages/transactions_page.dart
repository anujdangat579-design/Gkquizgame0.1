import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../providers/transactions_notifier.dart';
import '../providers/transactions_state.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsNotifierProvider.notifier).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);
    final notifier = ref.read(transactionsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
            onSelected: (type) => notifier.loadTransactions(type: type),
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('All')),
              PopupMenuItem(value: TransactionType.entryFee, child: Text('Entry fees')),
              PopupMenuItem(value: TransactionType.prizePayout, child: Text('Prize payouts')),
              PopupMenuItem(value: TransactionType.refund, child: Text('Refunds')),
              PopupMenuItem(value: TransactionType.walletTopup, child: Text('Wallet top-ups')),
              PopupMenuItem(value: TransactionType.notePurchase, child: Text('Note purchases')),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.viewState == TransactionsViewState.loading && state.transactions.isEmpty) {
            return const LoadingIndicator();
          }
          if (state.viewState == TransactionsViewState.error && state.transactions.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadTransactions(type: state.typeFilter),
            );
          }
          if (state.transactions.isEmpty) {
            return const EmptyState(
              message: 'No transactions yet.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => notifier.loadTransactions(type: state.typeFilter),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) => _TransactionTile(transaction: state.transactions[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  IconData _iconFor(TransactionType type) {
    switch (type) {
      case TransactionType.entryFee:
        return Icons.emoji_events_outlined;
      case TransactionType.prizePayout:
        return Icons.card_giftcard;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.walletTopup:
        return Icons.add_card;
      case TransactionType.notePurchase:
        return Icons.menu_book_outlined;
      case TransactionType.other:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final isCredit = transaction.amount >= 0;

    late final Color statusColor;
    switch (transaction.status) {
      case TransactionStatus.completed:
        statusColor = semantic.success;
        break;
      case TransactionStatus.pending:
        statusColor = semantic.warning;
        break;
      case TransactionStatus.failed:
        statusColor = colorScheme.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(_iconFor(transaction.type), color: colorScheme.onSurfaceVariant),
        ),
        title: Text(transaction.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(transaction.createdAt)),
            Text(
              '${transaction.status.name[0].toUpperCase()}${transaction.status.name.substring(1)}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Text(
          '${isCredit ? '+' : ''}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isCredit ? semantic.success : colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
