import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/competition_control_snapshot.dart';
import '../providers/competition_control_notifier.dart';
import '../providers/competition_control_state.dart';
import '../widgets/competition_control_actions.dart';
import '../widgets/competition_status_badge.dart';
import '../widgets/current_match_card.dart';
import '../widgets/dashboard_alerts_panel.dart';
import '../widgets/live_connection_indicator.dart';
import '../widgets/live_stats_grid.dart';
import '../widgets/next_match_preview_card.dart';

/// Admin's real-time control panel for a single competition: status,
/// waiting-queue size, the match currently in progress, a preview of
/// what's queued up next, headline stats, active alerts, and the
/// Start/Pause/Resume/End controls.
///
/// UI only — every mutating action and every field sourced from the
/// backend is marked with a `TODO(backend)` in
/// [CompetitionControlNotifier], which currently self-seeds mock data
/// and simulates auto-refresh locally so this screen is fully
/// interactive without a server. Auto-refresh is *architected* around
/// Socket.IO (`CompetitionControlSocketService`, wired up in the
/// notifier's `_connectLiveUpdates`) with that local simulation as the
/// fallback while no real socket exists to connect to — see
/// `WaitingQueuePage`'s doc comment for the same
/// socket-with-polling-fallback pattern already used elsewhere in this
/// app.
///
/// Does not touch or import any player-facing screen (quiz, waiting
/// queue, opponent-found, leaderboard, etc.) — entirely new files.
class CompetitionControlDashboardPage extends ConsumerWidget {
  final String competitionId;

  const CompetitionControlDashboardPage({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = competitionControlNotifierProvider(competitionId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.competitionName.isEmpty ? 'Competition Control' : state.competitionName),
        actions: [
          LiveConnectionIndicator(isConnected: state.isLiveConnected),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.viewState == CompetitionControlViewState.loading && state.competitionName.isEmpty) {
            return const LoadingIndicator();
          }

          if (state.viewState == CompetitionControlViewState.error && state.competitionName.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: notifier.loadDashboard,
            );
          }

          return RefreshIndicator(
            onRefresh: notifier.loadDashboard,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (state.errorMessage != null) ...[
                      _InlineErrorBanner(message: state.errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _HeaderRow(status: state.status, playersWaiting: state.playersWaiting),
                    const SizedBox(height: AppSpacing.lg),
                    isWide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 3, child: CurrentMatchCard(match: state.currentMatch)),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(flex: 2, child: NextMatchPreviewCard(preview: state.nextMatch ?? const NextMatchPreview())),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              CurrentMatchCard(match: state.currentMatch),
                              const SizedBox(height: AppSpacing.lg),
                              NextMatchPreviewCard(preview: state.nextMatch ?? const NextMatchPreview()),
                            ],
                          ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Live Statistics', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    LiveStatsGrid(stats: state.stats, crossAxisCount: isWide ? 4 : 2),
                    const SizedBox(height: AppSpacing.xxl),
                    DashboardAlertsPanel(alerts: state.alerts, onDismiss: notifier.dismissAlert),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Controls', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    CompetitionControlActions(
                      status: state.status,
                      pendingAction: state.pendingAction,
                      onStart: () => _confirmAndRun(
                        context,
                        title: 'Start competition?',
                        message: 'Matchmaking will begin immediately and players in the queue will start getting paired.',
                        isDestructive: false,
                        confirmLabel: 'Start',
                        action: notifier.startCompetition,
                      ),
                      onPauseMatchmaking: notifier.pauseMatchmaking,
                      onResumeMatchmaking: notifier.resumeMatchmaking,
                      onEnd: () => _confirmAndRun(
                        context,
                        title: 'End competition?',
                        message: 'No new matches will be created. Any match currently in progress will be allowed to finish.',
                        confirmLabel: 'End competition',
                        action: notifier.endCompetition,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() action,
    String confirmLabel = 'Confirm',
    bool isDestructive = true,
  }) async {
    final confirmed = await showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    );
    if (confirmed) await action();
  }
}

class _HeaderRow extends StatelessWidget {
  final CompetitionControlStatus status;
  final int playersWaiting;

  const _HeaderRow({required this.status, required this.playersWaiting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        CompetitionStatusBadge(status: status),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$playersWaiting waiting',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;
  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: TextStyle(color: colorScheme.onErrorContainer))),
        ],
      ),
    );
  }
}
