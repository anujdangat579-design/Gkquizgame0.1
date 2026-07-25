import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/player_statistics.dart';
import '../repositories/profile_repository.dart';

class GetPlayerStatistics implements UseCase<PlayerStatistics, NoParams> {
  final ProfileRepository repository;

  GetPlayerStatistics(this.repository);

  @override
  Future<Either<Failure, PlayerStatistics>> call(NoParams params) {
    return repository.getStatistics();
  }
}
