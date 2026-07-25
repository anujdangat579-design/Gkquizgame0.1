import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/leaderboard.dart';
import '../repositories/leaderboard_repository.dart';

class GetLeaderboardParams extends Equatable {
  final LeaderboardRange range;

  const GetLeaderboardParams({required this.range});

  @override
  List<Object?> get props => [range];
}

class GetLeaderboard implements UseCase<LeaderboardBoard, GetLeaderboardParams> {
  final LeaderboardRepository repository;

  GetLeaderboard(this.repository);

  @override
  Future<Either<Failure, LeaderboardBoard>> call(GetLeaderboardParams params) {
    return repository.getLeaderboard(range: params.range);
  }
}
