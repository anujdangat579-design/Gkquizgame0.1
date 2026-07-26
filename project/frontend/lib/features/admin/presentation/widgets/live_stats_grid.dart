import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/competition_control_snapshot.dart';

/// Four stat tiles laid out 2-across on narrow phones and 4-across once
/// there's room (tablets, or a phone in landscape) — see
/// `CompetitionControlDashboardPage`'s `LayoutBuilder` for the
/// responsive breakpoint this reacts to via `crossAxisCount`.
class LiveStatsGrid extends StatelessWidget {
  final LiveStats stats;
  final int crossAxisCount;

  const LiveStatsGrid({super.key, required this.stats, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    final tiles = [
      _StatTile(
        label: 'Total Players',
        value: stats.totalPlayers,
        icon: Icons.groups_outlined,
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
      _StatTile(
        label: 'Matches Completed',
        value: stats.matchesCompleted,
        icon: Icons.task_alt,
        background: semantic.successContainer,
        foreground: semantic.onSuccessContainer,
      ),
      _StatTile(
        label: 'Matches Running',
        value: stats.matchesRunning,
        icon: Icons.bolt,
        background: semantic.infoContainer,
        foreground: semantic.onInfoContainer,
      ),
      _StatTile(
        label: 'Players Waiting',
        value: stats.playersWaiting,
        icon: Icons.hourglass_top,
        background: semantic.warningContainer,
        foreground: semantic.onWarningContainer,
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(color: foreground, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
