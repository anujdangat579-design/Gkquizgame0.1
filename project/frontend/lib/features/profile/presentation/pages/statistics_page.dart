import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/player_statistics.dart';
import '../providers/statistics_notifier.dart';
import '../providers/statistics_state.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statisticsNotifierProvider.notifier).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsNotifierProvider);
    final notifier = ref.read(statisticsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Builder(
        builder: (context) {
          if (state.viewState == StatisticsViewState.loading && state.statistics == null) {
            return const LoadingIndicator();
          }
          if (state.viewState == StatisticsViewState.error && state.statistics == null) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadStatistics(),
            );
          }
          if (state.statistics == null) {
            return const EmptyState(
              message: 'No statistics yet — play a match to get started.',
              icon: Icons.bar_chart_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => notifier.loadStatistics(),
            child: _StatisticsView(statistics: state.statistics!),
          );
        },
      ),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  final PlayerStatistics statistics;

  const _StatisticsView({required this.statistics});

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(mobile: 2, tablet: 3, desktop: 4);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: [
            _StatCard(label: 'Matches', value: '${statistics.totalMatches}', icon: Icons.sports_esports),
            _StatCard(label: 'Wins', value: '${statistics.wins}', icon: Icons.emoji_events_outlined),
            _StatCard(label: 'Losses', value: '${statistics.losses}', icon: Icons.close),
            _StatCard(label: 'Draws', value: '${statistics.draws}', icon: Icons.remove),
            _StatCard(
              label: 'Win rate',
              value: '${(statistics.winRate * 100).toStringAsFixed(0)}%',
              icon: Icons.trending_up,
            ),
            _StatCard(
              label: 'Accuracy',
              value: '${(statistics.accuracy * 100).toStringAsFixed(0)}%',
              icon: Icons.gps_fixed,
            ),
            _StatCard(
                label: 'Current streak', value: '${statistics.currentStreak}', icon: Icons.local_fire_department),
            _StatCard(label: 'Best streak', value: '${statistics.bestStreak}', icon: Icons.star_outline),
            _StatCard(label: 'Points earned', value: '${statistics.totalPointsEarned}', icon: Icons.stars),
          ],
        ),
        if (statistics.categoryBreakdown != null && statistics.categoryBreakdown!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text('By category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...statistics.categoryBreakdown!.map(
            (stat) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text(stat.category),
                subtitle: Text('${stat.matchesPlayed} matches · ${stat.wins} wins'),
                trailing: Text('${(stat.accuracy * 100).toStringAsFixed(0)}% acc.'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
