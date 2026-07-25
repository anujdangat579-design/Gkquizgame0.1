import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../competition/presentation/widgets/circular_timer.dart';
import '../../domain/entities/competition_control_snapshot.dart';

class CurrentMatchCard extends StatelessWidget {
  final CurrentMatch? match;

  const CurrentMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = this.match;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: match == null
            ? EmptyState(
                message: 'No match currently in progress',
                icon: Icons.sports_esports_outlined,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LiveBadge(),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Current Match', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: _PlayerColumn(name: match.playerA.name, score: match.playerA.score)),
                      _MatchTimer(startedAt: match.startedAt, durationSeconds: match.durationSeconds),
                      Expanded(child: _PlayerColumn(name: match.playerB.name, score: match.playerB.score, alignEnd: true)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final String name;
  final int score;
  final bool alignEnd;

  const _PlayerColumn({required this.name, required this.score, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text('Score: $score', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Match timer. Uses [CircularTimer] as a countdown ring when the match
/// has a known fixed length; otherwise falls back to a plain count-up
/// "mm:ss" — both read off `startedAt` each rebuild (see
/// `CompetitionControlNotifier`'s 1s ticker), so the number is always
/// correct even across a screen rebuild, never drifting from a locally
/// incremented counter.
class _MatchTimer extends StatelessWidget {
  final DateTime startedAt;
  final int? durationSeconds;

  const _MatchTimer({required this.startedAt, this.durationSeconds});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(startedAt).inSeconds.clamp(0, 1 << 30);

    if (durationSeconds != null) {
      final remaining = (durationSeconds! - elapsed).clamp(0, durationSeconds!);
      return CircularTimer(
        secondsLeft: remaining,
        totalSeconds: durationSeconds!,
        size: 64,
        labelBuilder: (s) => _formatDuration(s),
      );
    }

    final minutes = (elapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsed % 60).toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('VS', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$minutes:$seconds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }

  String _formatDuration(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: semantic.successContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        'LIVE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: semantic.onSuccessContainer,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
