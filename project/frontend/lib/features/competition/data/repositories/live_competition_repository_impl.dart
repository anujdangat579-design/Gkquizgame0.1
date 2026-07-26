import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/live_competition.dart';
import '../../domain/repositories/live_competition_repository.dart';
import '../datasources/live_competition_remote_data_source.dart';

/// Concrete implementation the DI container binds to
/// [LiveCompetitionRepository]. Same `_guard` shape as
/// `CategoryRepositoryImpl` / `CompetitionRepositoryImpl`.
class LiveCompetitionRepositoryImpl implements LiveCompetitionRepository {
  final LiveCompetitionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LiveCompetitionRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<LiveCompetition>>> getLiveCompetitions({String? category}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final competitions = await remoteDataSource.getLiveCompetitions(category: category);
      return Right(competitions);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
