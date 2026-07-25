import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/player_badge.dart';
import '../repositories/profile_repository.dart';

class GetBadges implements UseCase<List<PlayerBadge>, NoParams> {
  final ProfileRepository repository;

  GetBadges(this.repository);

  @override
  Future<Either<Failure, List<PlayerBadge>>> call(NoParams params) {
    return repository.getBadges();
  }
}
