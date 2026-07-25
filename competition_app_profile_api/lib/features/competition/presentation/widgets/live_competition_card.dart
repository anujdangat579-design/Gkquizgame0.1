import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Card for a player-facing live quiz competition — distinct from
/// `CompetitionCard` (the admin's enabled/disabled management row).
/// This shows the fields a player deciding whether to join would care
/// about: category, entry fee, question count, time, how many others
/// are already waiting, and whether it's still joinable.
///
/// Takes plain values and an `onJoin` callback rather than a `LiveCompetition`
/// entity directly, so it stays reusable outside `LiveCompetitionsPage`
/// too. `LiveCompetitionsPage` is what maps `LiveCompetition` (backed by
/// `liveCompetitionNotifierProvider` -> `GetLiveCompetitions`, mirroring
/// how `Competition` backs `CompetitionCard`) onto these fields.
class LiveCompetitionCard extends StatelessWidget {
  final String category;
  final num entryFee;
  final int questionCount;
  final String timeLabel;
  final int playersWaiting;
  final bool isLive;
  final VoidCallback? onJoin;

  const LiveCompetitionCard({
    super.key,
    required this.category,
    required this.entryFee,
    required this.questionCount,
    required this.timeLabel,
    required this.playersWaiting,
    required this.isLive,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _CategoryChip(category: category),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusBadge(isLive: isLive, semantic: semantic, colorScheme: colorScheme),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.currency_rupee,
                    label: 'Entry fee',
                    value: currencyFormat.format(entryFee),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.quiz_outlined,
                    label: 'Questions',
                    value: '$questionCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.schedule_outlined,
                    label: 'Time',
                    value: timeLabel,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.people_outline,
                    label: 'Players waiting',
                    value: '$playersWaiting',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLive ? onJoin : null,
                child: Text(isLive ? 'Join now' : 'Closed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        category,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isLive;
  final AppSemanticColors semantic;
  final ColorScheme colorScheme;

  const _StatusBadge({
    required this.isLive,
    required this.semantic,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final background = isLive ? semantic.successContainer : semantic.neutralContainer;
    final foreground = isLive ? semantic.onSuccessContainer : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isLive ? 'Live' : 'Closed',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
