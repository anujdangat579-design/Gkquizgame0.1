import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../injection_container.dart';
import '../../../matchmaking/data/services/matchmaking_socket_service.dart';
import '../../../matchmaking/domain/entities/matchmaking_entry.dart';
import '../../../matchmaking/domain/usecases/get_matchmaking_status.dart';
import '../../../matchmaking/domain/usecases/leave_matchmaking_queue.dart';
import '../../routes/competition_routes.dart';
import 'opponent_found_page.dart' show OpponentFoundArgs, QueuePlayer;

/// Everything `CompetitionDetailsPage` hands off to this page via
/// `extra` once `joinCompetitionNotifierProvider` confirms the entry fee
/// was paid and `EnterMatchmakingQueue` placed the player in the pool —
/// see `JoinCompetitionState.matchmakingEntry`.
class WaitingQueueArgs {
  final String category;
  final String queueId;
  final int initialQueuePosition;
  final int initialPlayersAhead;
  final int initialEstimatedWaitSeconds;

  const WaitingQueueArgs({
    required this.category,
    required this.queueId,
    required this.initialQueuePosition,
    required this.initialPlayersAhead,
    required this.initialEstimatedWaitSeconds,
  });
}

/// Where this player currently sits in the matchmaking pipeline.
/// [waiting] is the only phase the player can still back out of — once
/// matching starts, the entry fee has been committed to a match attempt.
enum _QueueStatus { waiting, matching, matched }

extension on _QueueStatus {
  String get label {
    switch (this) {
      case _QueueStatus.waiting:
        return 'Waiting for players';
      case _QueueStatus.matching:
        return 'Matching you now';
      case _QueueStatus.matched:
        return 'Opponent found';
    }
  }

  String get description {
    switch (this) {
      case _QueueStatus.waiting:
        return 'Hang tight — we\'re lining up an opponent at your skill level.';
      case _QueueStatus.matching:
        return 'Locking in your match. This usually takes a few seconds.';
      case _QueueStatus.matched:
        return 'Get ready — the competition is about to begin.';
    }
  }

  IconData get icon {
    switch (this) {
      case _QueueStatus.waiting:
        return Icons.hourglass_top_outlined;
      case _QueueStatus.matching:
        return Icons.sync_outlined;
      case _QueueStatus.matched:
        return Icons.emoji_events_outlined;
    }
  }
}

/// Waiting Queue screen — shown right after payment succeeds on
/// `CompetitionDetailsPage`, while the player waits to be matched into a
/// live competition.
///
/// `initial*` fields are seeded from the real `MatchmakingEntry` the
/// backend returned from `EnterMatchmakingQueue` (see
/// `JoinCompetitionState.matchmakingEntry`). From there, updates are
/// driven by two sources:
/// - [_startSocketUpdates] — the primary source, a Socket.IO
///   subscription (`MatchmakingSocketService.watchQueue`) that pushes
///   position/players-ahead/wait-time/status the moment they change.
/// - [_startPolling] — a `GetMatchmakingStatus` REST poll kept running
///   as a fallback until the socket delivers its first update, and
///   resumed automatically if the socket disconnects (see
///   `_onSocketError`), so the player never gets stuck stale if
///   realtime is unavailable.
///
/// [_handleCancel] calls the real `LeaveMatchmakingQueue` use case via
/// `widget.queueId`, and also unsubscribes the socket via
/// `MatchmakingSocketService.stopWatching`. [_startFakeProgress] remains
/// only as a fallback for the (should not happen in the paid-join flow)
/// case where this page is reached without a `queueId`.
/// - Once an update reports `MatchmakingStatus.matched`,
///   [_navigateToOpponentFound] replaces this page with
///   `OpponentFoundPage` (`CompetitionRoutes.opponentFoundPath`),
///   passing the matched entry's opponent/self snapshot as
///   `OpponentFoundArgs`.
///
/// Routed at `/competitions/live/details/:id/queue`
/// (`CompetitionRoutes.queuePath`) — `CompetitionDetailsPage._handleJoin`
/// pushes here once `joinCompetitionNotifierProvider` confirms the entry
/// fee was paid and the player is joined, passing a [WaitingQueueArgs]
/// as `extra`.
class WaitingQueuePage extends StatefulWidget {
  final String competitionId;
  final String category;
  final String? queueId;
  final int initialQueuePosition;
  final int initialPlayersAhead;
  final int initialEstimatedWaitSeconds;

  const WaitingQueuePage({
    super.key,
    required this.competitionId,
    required this.category,
    this.queueId,
    this.initialQueuePosition = 4,
    this.initialPlayersAhead = 3,
    this.initialEstimatedWaitSeconds = 45,
  });

  @override
  State<WaitingQueuePage> createState() => _WaitingQueuePageState();
}

class _WaitingQueuePageState extends State<WaitingQueuePage> {
  static const _pollInterval = Duration(seconds: 2);

  late int _queuePosition = widget.initialQueuePosition;
  late int _playersAhead = widget.initialPlayersAhead;
  late int _estimatedWaitSeconds = widget.initialEstimatedWaitSeconds;
  _QueueStatus _status = _QueueStatus.waiting;
  bool _isCancelling = false;
  bool _isPolling = false;
  bool _socketActive = false;

  Timer? _ticker;
  StreamSubscription<MatchmakingEntry>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    final queueId = widget.queueId;
    if (queueId != null) {
      // Start the REST poll immediately as a fallback so the UI keeps
      // moving while the socket connects; it self-pauses once the
      // socket proves itself (see `_applyEntry`) and self-resumes if
      // the socket then errors/disconnects (see `_onSocketError`).
      _startPolling(queueId);
      _startSocketUpdates(queueId);
    } else {
      // No real queue entry to subscribe to (e.g. this screen was
      // reached without going through the paid join flow) — fall back
      // to the local fake ticker so the UI still progresses.
      _startFakeProgress();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _socketSubscription?.cancel();
    final queueId = widget.queueId;
    if (queueId != null) {
      sl<MatchmakingSocketService>().stopWatching(queueId);
    }
    super.dispose();
  }

  /// Subscribes to `MatchmakingSocketService.watchQueue(queueId)` for
  /// real-time push updates — the primary source of truth for this
  /// screen once connected. Falls back to `_onSocketError` (which keeps
  /// `_startPolling`'s REST fallback alive) if the subscription itself
  /// can't be established or the stream errors out later.
  Future<void> _startSocketUpdates(String queueId) async {
    try {
      final stream = await sl<MatchmakingSocketService>().watchQueue(queueId);
      if (!mounted) {
        sl<MatchmakingSocketService>().stopWatching(queueId);
        return;
      }
      _socketSubscription = stream.listen(
        (entry) {
          _socketActive = true;
          _applyEntry(entry);
        },
        onError: (Object error) => _onSocketError(queueId, error),
      );
    } catch (e) {
      _onSocketError(queueId, e);
    }
  }

  /// The socket subscription failed or dropped — make sure the REST
  /// fallback is (re-)running so the player keeps getting updates, just
  /// at `_pollInterval` cadence instead of instantly.
  void _onSocketError(String queueId, Object error) {
    debugPrint('Matchmaking socket error for $queueId: $error');
    _socketActive = false;
    if (mounted && (_ticker == null || !_ticker!.isActive)) {
      _startPolling(queueId);
    }
  }

  /// Drives the status ring/position/wait-time off the real matchmaking
  /// pipeline via `GetMatchmakingStatus`, polling every [_pollInterval]
  /// until the entry is `matched` (or `cancelled` server-side, e.g. an
  /// admin force-cancelling a stuck queue) — or until the Socket.IO
  /// subscription takes over (see `_applyEntry`). `_isPolling` guards
  /// against overlapping requests if a response is slow to come back
  /// before the next tick fires.
  void _startPolling(String queueId) {
    _ticker?.cancel();
    _ticker = Timer.periodic(_pollInterval, (timer) async {
      if (!mounted || _isPolling) return;
      if (_socketActive) {
        // The socket has taken over — stop the REST fallback until/
        // unless `_onSocketError` restarts it.
        timer.cancel();
        return;
      }
      _isPolling = true;

      final result = await sl<GetMatchmakingStatus>()(queueId);
      _isPolling = false;
      if (!mounted) return;

      result.fold(
        (failure) {
          // Transient poll failures shouldn't interrupt the player's
          // wait with an error state — just log and retry next tick.
          debugPrint('GetMatchmakingStatus($queueId) failed: ${failure.message}');
        },
        (entry) => _applyEntry(entry),
      );
    });
  }

  // Guards against navigating twice if more than one "matched" update
  // arrives (e.g. the socket delivers one right as a poll tick is also
  // in flight).
  bool _navigatedToMatch = false;

  void _applyEntry(MatchmakingEntry entry) {
    setState(() {
      _queuePosition = entry.queuePosition;
      _playersAhead = entry.playersAhead;
      _estimatedWaitSeconds = entry.estimatedWaitSeconds;
      _status = switch (entry.status) {
        MatchmakingStatus.queued => _QueueStatus.waiting,
        MatchmakingStatus.matching => _QueueStatus.matching,
        MatchmakingStatus.matched => _QueueStatus.matched,
        // Backend cancelled the entry out from under the player (e.g.
        // competition filled/closed while queued) — stop polling and
        // treat it the same as a self-initiated cancel.
        MatchmakingStatus.cancelled => _QueueStatus.waiting,
      };
    });

    if (entry.status == MatchmakingStatus.matched || entry.status == MatchmakingStatus.cancelled) {
      _ticker?.cancel();
      _socketSubscription?.cancel();
      final queueId = widget.queueId;
      if (queueId != null) {
        sl<MatchmakingSocketService>().stopWatching(queueId);
      }
    }

    if (entry.status == MatchmakingStatus.cancelled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This queue entry was cancelled. Please join again.')),
      );
      Navigator.of(context).pop();
      return;
    }

    if (entry.status == MatchmakingStatus.matched) {
      _navigateToOpponentFound(entry);
    }
  }

  /// Hands off to `OpponentFoundPage` the moment the server assigns a
  /// match, using [GoRouter.pushReplacement] rather than `push` — once
  /// matched, the entry fee is committed and there's no reason for the
  /// player to be able to swipe/back their way back into this queue
  /// screen.
  void _navigateToOpponentFound(MatchmakingEntry entry) {
    if (_navigatedToMatch || !mounted) return;
    _navigatedToMatch = true;

    context.pushReplacement(
      CompetitionRoutes.opponentFoundPath(widget.competitionId),
      extra: OpponentFoundArgs(
        you: QueuePlayer(
          name: entry.yourName ?? 'You',
          photoUrl: entry.yourPhotoUrl,
          rankLabel: entry.yourRankLabel ?? 'Unranked',
        ),
        opponent: QueuePlayer(
          name: entry.opponentName ?? 'Opponent',
          photoUrl: entry.opponentPhotoUrl,
          rankLabel: entry.opponentRankLabel ?? 'Unranked',
        ),
        category: widget.category,
      ),
    );
  }

  // Fallback only — used when this screen is reached without a real
  // `queueId` (see `initState`). Remove once every entry point supplies
  // one.
  void _startFakeProgress() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_status == _QueueStatus.waiting) {
          if (_estimatedWaitSeconds > 0) {
            _estimatedWaitSeconds -= 1;
          }
          if (_estimatedWaitSeconds > 0 && _estimatedWaitSeconds % 8 == 0 && _playersAhead > 0) {
            _playersAhead -= 1;
            _queuePosition = _queuePosition > 1 ? _queuePosition - 1 : 1;
          }
          if (_estimatedWaitSeconds <= 0 || _playersAhead == 0) {
            _status = _QueueStatus.matching;
          }
        } else if (_status == _QueueStatus.matching) {
          _status = _QueueStatus.matched;
          _ticker?.cancel();
        }
      });

      // No real MatchmakingEntry to source names from in this fallback
      // path — placeholder QueuePlayers only (see class doc comment on
      // when this path is hit).
      if (_status == _QueueStatus.matched) {
        _navigateToOpponentFound(
          const MatchmakingEntry(
            queueId: '',
            status: MatchmakingStatus.matched,
            queuePosition: 0,
            playersAhead: 0,
            estimatedWaitSeconds: 0,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canCancel = _status == _QueueStatus.waiting;

    return PopScope(
      canPop: canCancel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category),
          automaticallyImplyLeading: canCancel,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _PaymentVerifiedBanner(),
                      const SizedBox(height: AppSpacing.xxl),

                      Center(
                        child: _StatusRing(status: _status),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Text(
                          _status.label,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            _status.description,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.tag,
                              label: 'Queue position',
                              value: '#$_queuePosition',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.groups_outlined,
                              label: 'Players ahead',
                              value: '$_playersAhead',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatTile(
                        icon: Icons.schedule_outlined,
                        label: 'Estimated wait time',
                        value: _status == _QueueStatus.waiting
                            ? _formatSeconds(_estimatedWaitSeconds)
                            : 'Almost there',
                        fullWidth: true,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      _CompetitionStatusTile(status: _status),
                    ],
                  ),
                ),

                if (canCancel) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : _handleCancel,
                      style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cancel and leave queue'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final remaining = safeSeconds % 60;
    if (minutes == 0) return '${remaining}s';
    return '${minutes}m ${remaining}s';
  }

  Future<void> _handleCancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave queue?',
      message: 'Your entry fee will be refunded since matching hasn\'t started yet.',
      confirmLabel: 'Leave queue',
    );
    if (!confirmed) return;

    setState(() => _isCancelling = true);

    final queueId = widget.queueId;
    if (queueId != null) {
      final result = await sl<LeaveMatchmakingQueue>()(queueId);
      if (!mounted) return;
      final failureMessage = result.fold((failure) => failure.message, (_) => null);
      if (failureMessage != null) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage)));
        return;
      }
    } else {
      // No real queue entry to leave (e.g. this screen was reached
      // without going through the paid join flow) — nothing to call.
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (!mounted) return;
    setState(() => _isCancelling = false);
    Navigator.of(context).pop();
  }
}

class _PaymentVerifiedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.successContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 20, color: semantic.onSuccessContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Payment verified',
              style: theme.textTheme.titleSmall?.copyWith(color: semantic.onSuccessContainer),
            ),
          ),
          Icon(Icons.check_circle, size: 18, color: semantic.onSuccessContainer),
        ],
      ),
    );
  }
}

class _StatusRing extends StatelessWidget {
  final _QueueStatus status;

  const _StatusRing({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(status.icon, size: 36, color: colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}

class _CompetitionStatusTile extends StatelessWidget {
  final _QueueStatus status;

  const _CompetitionStatusTile({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    final isMatched = status == _QueueStatus.matched;
    final dotColor = isMatched
        ? semantic.success
        : status == _QueueStatus.matching
            ? semantic.warning
            : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Competition status', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  Text(status.label, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
            if (isMatched)
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
