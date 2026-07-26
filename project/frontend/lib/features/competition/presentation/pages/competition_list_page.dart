import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/competition_notifier.dart';
import '../providers/competition_state.dart';
import '../widgets/competition_card.dart';

class CompetitionListPage extends ConsumerStatefulWidget {
  const CompetitionListPage({super.key});

  @override
  ConsumerState<CompetitionListPage> createState() => _CompetitionListPageState();
}

class _CompetitionListPageState extends ConsumerState<CompetitionListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionNotifierProvider.notifier).loadCompetitions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(competitionNotifierProvider);
    final notifier = ref.read(competitionNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Competitions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('form'),
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (state.viewState == ViewState.loading && state.competitions.isEmpty) {
            return const LoadingIndicator();
          }

          if (state.viewState == ViewState.error && state.competitions.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadCompetitions(),
            );
          }

          if (state.competitions.isEmpty) {
            return const EmptyState(
              message: 'No competitions yet. Tap + to add one.',
              icon: Icons.emoji_events_outlined,
            );
          }

          final columns = context.responsive(mobile: 1, tablet: 2, desktop: 3);

          return RefreshIndicator(
            onRefresh: () => notifier.loadCompetitions(),
            child: columns == 1
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.competitions.length,
                    itemBuilder: (context, index) {
                      final competition = state.competitions[index];
                      return CompetitionCard(
                        competition: competition,
                        onTap: () => context.push('form', extra: competition),
                        onToggleStatus: () => notifier.toggleStatus(competition),
                        onDelete: () => _confirmDelete(context, notifier, competition.id),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 132,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: state.competitions.length,
                    itemBuilder: (context, index) {
                      final competition = state.competitions[index];
                      return CompetitionCard(
                        competition: competition,
                        onTap: () => context.push('form', extra: competition),
                        onToggleStatus: () => notifier.toggleStatus(competition),
                        onDelete: () => _confirmDelete(context, notifier, competition.id),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CompetitionNotifier notifier, String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete competition?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed) notifier.remove(id);
  }
}
