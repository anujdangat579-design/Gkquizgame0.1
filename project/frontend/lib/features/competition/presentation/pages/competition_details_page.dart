import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../payment/presentation/providers/join_competition_notifier.dart';
import '../../../payment/presentation/providers/join_competition_state.dart';
import '../../domain/entities/competition_details.dart';
import '../../routes/competition_routes.dart';
import '../providers/competition_details_notifier.dart';
import '../providers/competition_details_state.dart';
import 'waiting_queue_page.dart' show WaitingQueueArgs;

/// Competition details screen — shown after a player picks a live
/// competition (e.g. from `LiveCompetitionsPage`) and before joining.
/// Loads `CompetitionDetails` (per-difficulty pricing, question count,
/// time limit, rules) from the backend via
/// `competitionDetailsNotifierProvider(competitionId)` ->
/// `GetCompetitionDetails` -> `GET ApiConstants.competitionDetails(id)`
/// (see that constant's doc comment for the endpoint-path caveat).
///
/// `initialCategory` is only a fallback app-bar title shown while the
/// real details are loading (or if the load fails before ever
/// succeeding) — once `CompetitionDetails` arrives, its `category` is
/// used instead.
///
/// Wired into the router at `/competitions/live/details/:id`
/// (`CompetitionRoutes`); `LiveCompetitionsPage` pushes here when a
/// player taps "Join now" on a live competition.
class CompetitionDetailsPage extends ConsumerStatefulWidget {
  final String competitionId;
  final String? initialCategory;

  const CompetitionDetailsPage({
    super.key,
    required this.competitionId,
    this.initialCategory,
  });

  @override
  ConsumerState<CompetitionDetailsPage> createState() => _CompetitionDetailsPageState();
}

class _CompetitionDetailsPageState extends ConsumerState<CompetitionDetailsPage> {
  DifficultyPricing? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionDetailsNotifierProvider(widget.competitionId).notifier).loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(competitionDetailsNotifierProvider(widget.competitionId));
    final notifier = ref.read(competitionDetailsNotifierProvider(widget.competitionId).notifier);
    final joinState = ref.watch(joinCompetitionNotifierProvider(widget.competitionId));

    return Scaffold(
      appBar: AppBar(title: Text(state.details?.category ?? widget.initialCategory ?? 'Competition details')),
      body: Builder(
        builder: (context) {
          if (state.viewState == CompetitionDetailsViewState.loading && state.details == null) {
            return const LoadingIndicator();
          }

          if (state.viewState == CompetitionDetailsViewState.error && state.details == null) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadDetails(),
            );
          }

          final details = state.details;
          if (details == null) {
            return const EmptyState(
              message: 'This competition is no longer available.',
              icon: Icons.emoji_events_outlined,
            );
          }

          // Default to the first difficulty once details arrive, if the
          // player hasn't picked one yet (or the previous selection no
          // longer appears in a refreshed list).
          if (details.difficulties.isNotEmpty &&
              (_selected == null || !details.difficulties.contains(_selected))) {
            _selected = details.difficulties.first;
          }

          return _CompetitionDetailsBody(
            details: details,
            selected: _selected,
            isJoining: joinState.isInProgress,
            onSelect: (difficulty) => setState(() => _selected = difficulty),
            onJoin: () => _handleJoin(details),
          );
        },
      ),
    );
  }

  /// Runs the entry-fee payment (Cashfree Web Checkout) for the selected
  /// difficulty via `joinCompetitionNotifierProvider` — which, once the
  /// backend confirms both payment and entry, also calls the
  /// Matchmaking API (`EnterMatchmakingQueue`) to place the player in
  /// the live pool. Only after all of that succeeds do we push
  /// `WaitingQueuePage`, carrying the real queue entry via
  /// `WaitingQueueArgs`. A failed/cancelled payment (or a failed
  /// matchmaking call) leaves the player on this screen with the reason
  /// in a snackbar so they can retry.
  Future<void> _handleJoin(CompetitionDetails details) async {
    final selected = _selected;
    if (selected == null) return;

    final joined = await ref
        .read(joinCompetitionNotifierProvider(widget.competitionId).notifier)
        .join(difficultyLevel: selected.level);

    if (!mounted) return;

    if (joined) {
      final entry = ref.read(joinCompetitionNotifierProvider(widget.competitionId)).matchmakingEntry;
      context.push(
        CompetitionRoutes.queuePath(widget.competitionId),
        extra: entry == null
            ? null
            : WaitingQueueArgs(
                category: details.category,
                queueId: entry.queueId,
                initialQueuePosition: entry.queuePosition,
                initialPlayersAhead: entry.playersAhead,
                initialEstimatedWaitSeconds: entry.estimatedWaitSeconds,
              ),
      );
      return;
    }

    final message = ref.read(joinCompetitionNotifierProvider(widget.competitionId)).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Payment failed. Please try again.')),
    );
  }
}

class _CompetitionDetailsBody extends StatelessWidget {
  final CompetitionDetails details;
  final DifficultyPricing? selected;
  final bool isJoining;
  final ValueChanged<DifficultyPricing> onSelect;
  final VoidCallback onJoin;

  const _CompetitionDetailsBody({
    required this.details,
    required this.selected,
    required this.isJoining,
    required this.onSelect,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final canJoin = selected != null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.emoji_events_outlined, color: colorScheme.onPrimaryContainer, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(details.category, style: theme.textTheme.titleLarge),
                  Text(
                    'Pick a difficulty and join',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        if (details.difficulties.isNotEmpty) ...[
          Text('Difficulty', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: details.difficulties.map((difficulty) {
              final isLast = difficulty == details.difficulties.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
                  child: _DifficultyOption(
                    label: difficulty.label,
                    fee: currencyFormat.format(difficulty.entryFee),
                    isSelected: selected == difficulty,
                    onTap: () => onSelect(difficulty),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],

        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.quiz_outlined,
                label: 'Questions',
                value: '${details.questionCount}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _InfoTile(
                icon: Icons.schedule_outlined,
                label: 'Time',
                value: details.timeLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _InfoTile(
                icon: Icons.currency_rupee,
                label: 'Entry fee',
                value: selected != null ? currencyFormat.format(selected!.entryFee) : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        Text('Rules', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final rule in details.rules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 6, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(rule, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _NoCashPrizeNotice(),
        const SizedBox(height: AppSpacing.xxl),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: !canJoin || isJoining ? null : onJoin,
            child: isJoining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    canJoin
                        ? 'Join competition — ${currencyFormat.format(selected!.entryFee)}'
                        : 'Join competition',
                  ),
          ),
        ),
      ],
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  final String label;
  final String fee;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.label,
    required this.fee,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fee,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NoCashPrizeNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: semantic.onWarningContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No cash prize — this is a skill-based competition for score and ranking only. '
              'No real-money winnings are paid out.',
              style: theme.textTheme.bodySmall?.copyWith(color: semantic.onWarningContainer),
            ),
          ),
        ],
      ),
    );
  }
}
