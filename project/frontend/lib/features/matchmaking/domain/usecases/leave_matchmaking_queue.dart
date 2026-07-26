import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/matchmaking_repository.dart';

/// Takes the queue id directly as `Params` — same shape as
/// `VerifyPayment`.
class LeaveMatchmakingQueue implements UseCase<void, String> {
  final MatchmakingRepository repository;

  LeaveMatchmakingQueue(this.repository);

  @override
  Future<Either<Failure, void>> call(String queueId) {
    return repository.leaveQueue(queueId);
  }
}
