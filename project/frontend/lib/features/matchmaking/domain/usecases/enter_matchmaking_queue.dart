import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/matchmaking_entry.dart';
import '../repositories/matchmaking_repository.dart';

class EnterMatchmakingQueueParams extends Equatable {
  final String competitionId;
  final String orderId;

  const EnterMatchmakingQueueParams({required this.competitionId, required this.orderId});

  @override
  List<Object?> get props => [competitionId, orderId];
}

class EnterMatchmakingQueue implements UseCase<MatchmakingEntry, EnterMatchmakingQueueParams> {
  final MatchmakingRepository repository;

  EnterMatchmakingQueue(this.repository);

  @override
  Future<Either<Failure, MatchmakingEntry>> call(EnterMatchmakingQueueParams params) {
    return repository.enterQueue(competitionId: params.competitionId, orderId: params.orderId);
  }
}
