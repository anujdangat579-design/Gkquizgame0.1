import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../account/routes/account_routes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../competition/domain/entities/competition.dart';
import '../../../competition/presentation/providers/competition_notifier.dart';
import '../../../competition/presentation/providers/competition_state.dart';
import '../../../competition/presentation/widgets/competition_card.dart';
import '../../../competition/routes/competition_routes.dart';
import '../../../study_notes/routes/study_notes_routes.dart';
import '../../domain/entities/dashboard_statistics.dart';
import '../providers/dashboard_statistics_notifier.dart';
import '../providers/dashboard_statistics_state.dart';

/// Home dashboard — the shell's first tab, and the app's home screen.
///
/// Layout: a Material 3 [AppBar] carrying a notification action and a
/// profile avatar (tapping either is a placeholder for now — see
/// [_handleNotificationsTap] / the avatar's `onPressed`), a
/// [_WelcomeHeader] greeting, then the stats/quick-actions/recent-list
/// body.  Bottom navigation isn't built here — this page is one branch
/// of `MainShellPage`'s `NavigationBar`, which is what actually renders
/// it (see `core/routes/app_router.dart`).
///
/// Stat cards now come from `dashboardStatisticsNotifierProvider` (a
/// real backend aggregate — see `GetDashboardStatistics`), not a
/// client-side count of whichever single page of `GetCompetitions`
/// happened to be loaded. "Recent competitions" still reuses
/// `competitionNotifierProvider`, since that's a real list, not a stat.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionNotifierProvider.notifier).loadCompetitions();
      ref.read(dashboardStatisticsNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(competitionNotifierProvider);
    final notifier = ref.read(competitionNotifierProvider.notifier);
    final statisticsState = ref.watch(dashboardStatisticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => _handleNotificationsTap(context),
          ),
          IconButton(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            tooltip: 'Account',
            onPressed: () => context.go(AccountRoutes.home),
          ),
        ],
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

          return RefreshIndicator(
            onRefresh: () => Future.wait([
              notifier.loadCompetitions(),
              ref.read(dashboardStatisticsNotifierProvider.notifier).load(),
            ]),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const _WelcomeHeader(),
                const SizedBox(height: AppSpacing.xxl),

                _StatRow(statisticsState: statisticsState),
                const SizedBox(height: AppSpacing.xxl),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push('${CompetitionRoutes.list}/${CompetitionRoutes.form}'),
                        icon: const Icon(Icons.add),
                        label: const Text('New competition'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(CompetitionRoutes.list),
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('View all'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(StudyNotesRoutes.home),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Study Notes'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent competitions', style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () => context.go(CompetitionRoutes.list),
                      child: const Text('See all'),
                    ),
                  ],
                ),

                if (state.competitions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.lg),
                    child: EmptyState(
                      message: 'No competitions yet. Create your first one above.',
                      icon: Icons.emoji_events_outlined,
                    ),
                  )
                else
                  ..._recentCompetitions(state.competitions).map(
                    (competition) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: CompetitionCard(
                        competition: competition,
                        onTap: () => context.go(CompetitionRoutes.list),
                        onToggleStatus: () => notifier.toggleStatus(competition),
                        onDelete: () => _confirmDelete(context, notifier, competition.id),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Competition> _recentCompetitions(List<Competition> competitions) {
    final sorted = [...competitions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  void _handleNotificationsTap(BuildContext context) {
    // TODO(notifications-feature): replace with a real notifications list
    // once that feature exists (no domain/data layer for it yet).
    // Placeholder so the affordance isn't a dead tap target.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notifications aren't wired up yet")),
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

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Here's what's happening with your competitions",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Reads real aggregate totals from [DashboardStatisticsState] (backed by
/// `GetDashboardStatistics`) rather than counting a single loaded page of
/// competitions. Shows `0` for each card while the first load is still in
/// flight rather than a spinner, since these are secondary to the
/// competitions list above and a flash of `0 -> real value` is less
/// disruptive than a layout-shifting loading state here.
class _StatRow extends StatelessWidget {
  final DashboardStatisticsState statisticsState;

  const _StatRow({required this.statisticsState});

  @override
  Widget build(BuildContext context) {
    final DashboardStatistics stats = statisticsState.statistics;
    final disabled = stats.totalCompetitions - stats.activeCompetitions;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: stats.totalCompetitions,
            icon: Icons.emoji_events_outlined,
            background: Theme.of(context).colorScheme.primaryContainer,
            foreground: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Enabled',
            value: stats.activeCompetitions,
            icon: Icons.check_circle_outline,
            background: context.semanticColors.successContainer,
            foreground: context.semanticColors.onSuccessContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Disabled',
            value: disabled < 0 ? 0 : disabled,
            icon: Icons.pause_circle_outline,
            background: context.semanticColors.neutralContainer,
            foreground: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

