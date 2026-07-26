import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/match_history_entry.dart';
import '../providers/match_history_notifier.dart';
import '../providers/match_history_state.dart';

class MatchHistoryPage extends ConsumerStatefulWidget {
  const MatchHistoryPage({super.key});

  @override
  ConsumerState<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends ConsumerState<MatchHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchHistoryNotifierProvider.notifier).loadMatchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchHistoryNotifierProvider);
    final notifier = ref.read(matchHistoryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Match History')),
      body: Builder(
        builder: (context) {
          if (state.viewState == MatchHistoryViewState.loading && state.entries.isEmpty) {
            return const LoadingIndicator();
          }
          if (state.viewState == MatchHistoryViewState.error && state.entries.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadMatchHistory(),
            );
          }
          if (state.entries.isEmpty) {
            return const EmptyState(
              message: 'No matches played yet.',
              icon: Icons.sports_esports_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => notifier.loadMatchHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: state.entries.length,
              itemBuilder: (context, index) => _MatchHistoryTile(entry: state.entries[index]),
            ),
          );
        },
      ),
    );
  }
}

class _MatchHistoryTile extends StatelessWidget {
  final MatchHistoryEntry entry;

  const _MatchHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    late final Color badgeBg;
    late final Color badgeFg;
    late final String badgeLabel;
    switch (entry.outcome) {
      case MatchOutcome.win:
        badgeBg = semantic.successContainer;
        badgeFg = semantic.onSuccessContainer;
        badgeLabel = 'WIN';
        break;
      case MatchOutcome.loss:
        badgeBg = colorScheme.errorContainer;
        badgeFg = colorScheme.onErrorContainer;
        badgeLabel = 'LOSS';
        break;
      case MatchOutcome.draw:
        badgeBg = semantic.neutralContainer;
        badgeFg = colorScheme.onSurfaceVariant;
        badgeLabel = 'DRAW';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage:
              entry.opponent.photoUrl != null ? NetworkImage(entry.opponent.photoUrl!) : null,
          child: entry.opponent.photoUrl == null
              ? Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer)
              : null,
        ),
        title: Text('vs ${entry.opponent.name}'),
        subtitle: Text(
          '${entry.category} · ${entry.correctAnswers}/${entry.totalQuestions} correct\n'
          '${dateFormat.format(entry.playedAt)}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
              child: Text(
                badgeLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: badgeFg, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${entry.yourScore} - ${entry.opponentScore}'),
          ],
        ),
      ),
    );
  }
}
