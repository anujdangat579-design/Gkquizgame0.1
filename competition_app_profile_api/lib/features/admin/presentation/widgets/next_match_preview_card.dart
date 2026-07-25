import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/competition_control_snapshot.dart';

class NextMatchPreviewCard extends StatelessWidget {
  final NextMatchPreview preview;

  const NextMatchPreviewCard({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next Match', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (!preview.isReady)
              Row(
                children: [
                  Icon(Icons.hourglass_top, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Waiting for players to be matched…',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preview.playerA!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('vs', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ),
                  Expanded(
                    child: Text(
                      preview.playerB!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            if (preview.estimatedStartInSeconds != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Starts in ~${preview.estimatedStartInSeconds}s',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
