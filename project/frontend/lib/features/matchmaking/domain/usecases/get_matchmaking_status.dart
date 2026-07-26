import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/matchmaking_entry.dart';
import '../repositories/matchmaking_repository.dart';

/// Takes the queue id directly as `Params` — same shape as
/// `VerifyPayment` / `LeaveMatchmakingQueue`. Called on a poll interval
/// by `WaitingQueuePage` (see that page's doc comment) rather than
/// once, so it deliberately has no caching/memoization built in.
class GetMatchmakingStatus implements UseCase<MatchmakingEntry, String> {
  final MatchmakingRepository repository;

  GetMatchmakingStatus(this.repository);

  @override
  Future<Either<Failure, MatchmakingEntry>> call(String queueId) {
    return repository.getStatus(queueId);
  }
}
