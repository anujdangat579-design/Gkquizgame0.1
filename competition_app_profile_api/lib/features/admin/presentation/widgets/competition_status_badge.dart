import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/competition_control_snapshot.dart';

class CompetitionStatusBadge extends StatelessWidget {
  final CompetitionControlStatus status;

  const CompetitionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg, IconData icon, String label) = switch (status) {
      CompetitionControlStatus.running => (
          semantic.successContainer,
          semantic.onSuccessContainer,
          Icons.play_circle_fill,
          'Running',
        ),
      CompetitionControlStatus.paused => (
          semantic.warningContainer,
          semantic.onWarningContainer,
          Icons.pause_circle_filled,
          'Paused',
        ),
      CompetitionControlStatus.ended => (
          semantic.neutralContainer,
          colorScheme.onSurfaceVariant,
          Icons.stop_circle,
          'Ended',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
