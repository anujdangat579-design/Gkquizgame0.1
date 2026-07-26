import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// A minimal player snapshot for display purposes only — just enough to
/// render an avatar + name + rank on this screen. Once a real `Player`/
/// `User` entity with a matchmaking-facing shape exists, swap this out
/// for that instead of adding fields here.
class QueuePlayer {
  final String name;
  final String? photoUrl;
  final String rankLabel;

  const QueuePlayer({
    required this.name,
    this.photoUrl,
    this.rankLabel = 'Unranked',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Everything `WaitingQueuePage` hands off to this page via `extra`
/// once the matchmaking feed reports `MatchmakingStatus.matched` — see
/// `MatchmakingEntry.opponentName`/`yourName` and friends.
class OpponentFoundArgs {
  final QueuePlayer you;
  final QueuePlayer opponent;
  final String category;

  const OpponentFoundArgs({
    required this.you,
    required this.opponent,
    required this.category,
  });
}

/// Opponent Found screen — shown the moment matchmaking resolves at the
/// end of `WaitingQueuePage`, giving both players a beat to see who
/// they're facing before a 3-2-1 countdown drops them into the match.
///
/// UI only: [_startCountdown] just runs a local `Timer` and calls
/// [onCountdownComplete] (defaulting to popping the route) once it hits
/// zero. Once a real match/session layer exists, replace the timer with
/// a server-driven "match starting at T" signal (so both players' clocks
/// agree) and swap [onCountdownComplete] for actual navigation into the
/// live competition screen.
///
/// Routed at `/competitions/live/details/:id/opponent-found`
/// (`CompetitionRoutes.opponentFoundPath`) — `WaitingQueuePage` pushes
/// here (replacing itself in the stack) as soon as the matchmaking feed
/// reports a match, passing an [OpponentFoundArgs] built from the
/// matched `MatchmakingEntry` as `extra`.
class OpponentFoundPage extends StatefulWidget {
  final QueuePlayer you;
  final QueuePlayer opponent;
  final String category;
  final VoidCallback? onCountdownComplete;

  const OpponentFoundPage({
    super.key,
    required this.you,
    required this.opponent,
    required this.category,
    this.onCountdownComplete,
  });

  @override
  State<OpponentFoundPage> createState() => _OpponentFoundPageState();
}

class _OpponentFoundPageState extends State<OpponentFoundPage> {
  static const int _startFrom = 3;

  int _count = _startFrom;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_count <= 1) {
        _timer?.cancel();
        setState(() => _count = 0);
        if (widget.onCountdownComplete != null) {
          widget.onCountdownComplete!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() => _count -= 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Opponent found!',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CategoryChip(category: widget.category),
                const Spacer(),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _PlayerCard(player: widget.you, label: 'You', highlight: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'VS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PlayerCard(player: widget.opponent, label: 'Opponent', highlight: false),
                    ),
                  ],
                ),

                const Spacer(),
                _Countdown(count: _count, startFrom: _startFrom),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _count > 0 ? 'Get ready...' : 'Starting!',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: AppSpacing.xs),
          Text(
            category,
            style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final QueuePlayer player;
  final String label;
  final bool highlight;

  const _PlayerCard({required this.player, required this.label, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(highlight ? 3 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: highlight ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.secondaryContainer,
            backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
            child: player.photoUrl == null
                ? Text(
                    player.initials,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          player.name,
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          player.rankLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  final int count;
  final int startFrom;

  const _Countdown({required this.count, required this.startFrom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = count == 0 ? 1.0 : (startFrom - count + 1) / startFrom;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value.clamp(0, 1),
                strokeWidth: 5,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Text(
              count > 0 ? '$count' : 'GO',
              key: ValueKey(count),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
