import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/leaderboard.dart' as domain;
import '../providers/leaderboard_notifier.dart';
import '../providers/leaderboard_state.dart';
import 'opponent_found_page.dart' show QueuePlayer;

enum _LeaderboardRange { today, weekly, allTime }

extension on _LeaderboardRange {
  String get label {
    switch (this) {
      case _LeaderboardRange.today:
        return 'Today';
      case _LeaderboardRange.weekly:
        return 'This week';
      case _LeaderboardRange.allTime:
        return 'All time';
    }
  }

  /// Maps to the domain enum `LeaderboardNotifier.loadLeaderboard`
  /// actually takes — kept as a distinct UI-only enum (same split as
  /// `QuestionOutcome`/`MatchResultQuestion.isCorrect`) so this page
  /// doesn't need to know the domain layer's naming for its segmented
  /// control.
  domain.LeaderboardRange get toDomain {
    switch (this) {
      case _LeaderboardRange.today:
        return domain.LeaderboardRange.today;
      case _LeaderboardRange.weekly:
        return domain.LeaderboardRange.weekly;
      case _LeaderboardRange.allTime:
        return domain.LeaderboardRange.allTime;
    }
  }
}

/// One ranked row, as rendered by this page. UI-only local model — maps
/// 1:1 from `LeaderboardRankEntry` (the domain source of truth), same
/// split as `QuestionReport`/`MatchResultQuestion`.
class LeaderboardEntry {
  final int rank;
  final QueuePlayer player;
  final int points;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.player,
    required this.points,
    this.isCurrentUser = false,
  });
}

/// Leaderboard screen — players ranked by points across a selectable
/// time range, with the top 3 called out as a podium. Backed by
/// `leaderboardNotifierProvider` -> `GetLeaderboard` -> `GET
/// ApiConstants.leaderboard` (see that constant's doc comment for the
/// endpoint-path caveat). Same load-on-init / loading-error shape as
/// `LiveCompetitionsPage`.
///
/// Not yet added to any router or the bottom nav's tabs; construct
/// directly, or add a fourth `_Destination` to `MainShellPage` once this
/// is wired into the player-facing navigation.
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  _LeaderboardRange _range = _LeaderboardRange.weekly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardNotifierProvider.notifier).loadLeaderboard(range: _range.toDomain);
    });
  }

  void _handleRangeChanged(_LeaderboardRange range) {
    setState(() => _range = range);
    ref.read(leaderboardNotifierProvider.notifier).loadLeaderboard(range: range.toDomain);
  }

  LeaderboardEntry _toUiEntry(domain.LeaderboardRankEntry entry) {
    return LeaderboardEntry(
      rank: entry.rank,
      player: QueuePlayer(name: entry.player.name, photoUrl: entry.player.photoUrl, rankLabel: entry.player.rankLabel),
      points: entry.points,
      isCurrentUser: entry.isCurrentUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardNotifierProvider);
    final notifier = ref.read(leaderboardNotifierProvider.notifier);
    final board = state.board;

    final entries = board?.entries.map(_toUiEntry).toList() ?? const <LeaderboardEntry>[];
    final podium = entries.where((e) => e.rank <= 3).toList();
    final rest = entries.where((e) => e.rank > 3).toList();

    // The pinned "You" row: prefer whatever the backend sent separately
    // as `currentUserEntry` (see that field's doc comment on
    // `LeaderboardBoard`) over scanning `entries`, since a player outside
    // the top N wouldn't be in `entries` at all.
    final pinnedCurrentUser = board?.currentUserEntry != null ? _toUiEntry(board!.currentUserEntry!) : null;
    final currentUserInEntries = entries.where((e) => e.isCurrentUser).firstOrNull;
    final showPinnedRow = pinnedCurrentUser != null && currentUserInEntries == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: SegmentedButton<_LeaderboardRange>(
              segments: const [
                ButtonSegment(value: _LeaderboardRange.today, label: Text('Today')),
                ButtonSegment(value: _LeaderboardRange.weekly, label: Text('Weekly')),
                ButtonSegment(value: _LeaderboardRange.allTime, label: Text('All time')),
              ],
              selected: {_range},
              onSelectionChanged: (selection) => _handleRangeChanged(selection.first),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.viewState == LeaderboardViewState.loading && entries.isEmpty) {
                  return const LoadingIndicator();
                }

                if (state.viewState == LeaderboardViewState.error && entries.isEmpty) {
                  return ErrorState(
                    message: state.errorMessage ?? 'Something went wrong',
                    onRetry: () => notifier.loadLeaderboard(range: _range.toDomain),
                  );
                }

                if (entries.isEmpty) {
                  return const EmptyState(
                    message: 'No rankings yet for this range.',
                    icon: Icons.leaderboard_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => notifier.loadLeaderboard(range: _range.toDomain),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _Podium(entries: podium),
                      const SizedBox(height: AppSpacing.xxl),
                      for (final entry in rest) ...[
                        _RankRow(entry: entry),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (showPinnedRow) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _RankRow(entry: pinnedCurrentUser!, pinned: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  LeaderboardEntry? _byRank(int rank) => entries.where((e) => e.rank == rank).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final first = _byRank(1);
    final second = _byRank(2);
    final third = _byRank(3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null) Expanded(child: _PodiumSpot(entry: second, height: 96, medalColor: const Color(0xFFC0C0C0))),
        const SizedBox(width: AppSpacing.sm),
        if (first != null) Expanded(child: _PodiumSpot(entry: first, height: 124, medalColor: const Color(0xFFFFD700), isFirst: true)),
        const SizedBox(width: AppSpacing.sm),
        if (third != null) Expanded(child: _PodiumSpot(entry: third, height: 76, medalColor: const Color(0xFFCD7F32))),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _PodiumSpot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color medalColor;
  final bool isFirst;

  const _PodiumSpot({
    required this.entry,
    required this.height,
    required this.medalColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) Icon(Icons.emoji_events, color: medalColor, size: 28),
        const SizedBox(height: AppSpacing.xs),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: isFirst ? 32 : 26,
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                entry.player.initials,
                style: (isFirst ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
                    ?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w700),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.rank}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          entry.player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          '${entry.points} pts',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool pinned;

  const _RankRow({required this.entry, this.pinned = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCurrentUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isCurrentUser ? Border.all(color: colorScheme.primary, width: 1.5) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrentUser ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.secondaryContainer,
            child: Text(
              entry.player.initials,
              style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isCurrentUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                  ),
                ),
                Text(
                  entry.player.rankLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCurrentUser
                        ? colorScheme.onPrimaryContainer.withOpacity(0.75)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.points}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isCurrentUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'pts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCurrentUser ? colorScheme.onPrimaryContainer.withOpacity(0.75) : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
