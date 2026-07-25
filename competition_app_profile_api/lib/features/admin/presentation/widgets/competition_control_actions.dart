import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/competition_control_snapshot.dart';
import '../providers/competition_control_state.dart';

class CompetitionControlActions extends StatelessWidget {
  final CompetitionControlStatus status;
  final CompetitionControlAction? pendingAction;
  final VoidCallback onStart;
  final VoidCallback onPauseMatchmaking;
  final VoidCallback onResumeMatchmaking;
  final VoidCallback onEnd;

  const CompetitionControlActions({
    super.key,
    required this.status,
    required this.pendingAction,
    required this.onStart,
    required this.onPauseMatchmaking,
    required this.onResumeMatchmaking,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isEnded = status == CompetitionControlStatus.ended;
    final isRunning = status == CompetitionControlStatus.running;
    final isPaused = status == CompetitionControlStatus.paused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEnded)
          LoadingButton(
            isLoading: pendingAction == CompetitionControlAction.start,
            onPressed: onStart,
            child: const _ButtonLabel(icon: Icons.play_arrow, label: 'Start Competition'),
          ),
        if (!isEnded) ...[
          Row(
            children: [
              Expanded(
                child: isRunning
                    ? OutlinedButton.icon(
                        onPressed: pendingAction == null ? onPauseMatchmaking : null,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause Matchmaking'),
                      )
                    : LoadingButton(
                        isLoading: pendingAction == CompetitionControlAction.resumeMatchmaking,
                        onPressed: isPaused ? onResumeMatchmaking : null,
                        child: const _ButtonLabel(icon: Icons.play_arrow, label: 'Resume Matchmaking'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: pendingAction == null ? onEnd : null,
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End Competition'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ButtonLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}
