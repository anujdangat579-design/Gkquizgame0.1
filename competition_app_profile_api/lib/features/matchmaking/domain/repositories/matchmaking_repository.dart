import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/matchmaking_entry.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (MatchmakingRepositoryImpl); the presentation
/// layer never talks to it directly, only through the
/// `EnterMatchmakingQueue` / `GetMatchmakingStatus` /
/// `LeaveMatchmakingQueue` use cases — same shape as [PaymentRepository].
abstract class MatchmakingRepository {
  /// Places the (already-paid) player into the matchmaking pool for
  /// `competitionId`. `orderId` is the confirmed-paid order from
  /// `VerifyPayment`, so the backend can tie the queue entry back to a
  /// specific entry fee.
  Future<Either<Failure, MatchmakingEntry>> enterQueue({
    required String competitionId,
    required String orderId,
  });

  /// Polls the current state of `queueId` — used by `WaitingQueuePage`
  /// to drive its status ring/position/wait-time off the real
  /// matchmaking pipeline instead of a local fake ticker.
  Future<Either<Failure, MatchmakingEntry>> getStatus(String queueId);

  /// Leaves the queue for `queueId` — only meaningful while the entry's
  /// status is still `queued` (see `WaitingQueuePage._handleCancel`).
  Future<Either<Failure, void>> leaveQueue(String queueId);
}
