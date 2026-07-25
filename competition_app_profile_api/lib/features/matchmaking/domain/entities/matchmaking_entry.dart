import 'package:equatable/equatable.dart';

/// Where this queue entry currently sits in the backend's matchmaking
/// pipeline. Mirrors the phases `WaitingQueuePage` already renders
/// (`_QueueStatus`) so the real feed can eventually replace that page's
/// local fake ticker one-for-one.
enum MatchmakingStatus { queued, matching, matched, cancelled }

/// Result of `EnterMatchmakingQueue` (`ApiConstants.matchmakingQueue`) —
/// the backend's confirmation that a paid player has been placed into
/// the live matchmaking pool for a competition. `queueId` is what
/// `WaitingQueuePage` sends back for "Cancel and leave queue"
/// (`ApiConstants.matchmakingQueueEntry`).
class MatchmakingEntry extends Equatable {
  final String queueId;
  final MatchmakingStatus status;
  final int queuePosition;
  final int playersAhead;
  final int estimatedWaitSeconds;

  /// Populated once [status] reaches [MatchmakingStatus.matched] — the
  /// server's assigned opponent for this queue entry. Null at every
  /// earlier status. Used by `WaitingQueuePage` to build the
  /// `QueuePlayer` it hands off to `OpponentFoundPage`.
  final String? opponentId;
  final String? opponentName;
  final String? opponentPhotoUrl;
  final String? opponentRankLabel;

  /// Same shape, but for the current player — also only expected
  /// alongside [MatchmakingStatus.matched]. Kept here (rather than
  /// sourced from `AccountNotifier`) since `WaitingQueuePage` doesn't
  /// otherwise hold a reference to the player's own profile.
  final String? yourName;
  final String? yourPhotoUrl;
  final String? yourRankLabel;

  const MatchmakingEntry({
    required this.queueId,
    required this.status,
    required this.queuePosition,
    required this.playersAhead,
    required this.estimatedWaitSeconds,
    this.opponentId,
    this.opponentName,
    this.opponentPhotoUrl,
    this.opponentRankLabel,
    this.yourName,
    this.yourPhotoUrl,
    this.yourRankLabel,
  });

  @override
  List<Object?> get props => [
        queueId,
        status,
        queuePosition,
        playersAhead,
        estimatedWaitSeconds,
        opponentId,
        opponentName,
        opponentPhotoUrl,
        opponentRankLabel,
        yourName,
        yourPhotoUrl,
        yourRankLabel,
      ];
}
