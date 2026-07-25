import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/competition_details.dart';
import '../../domain/repositories/competition_details_repository.dart';
import '../datasources/competition_details_remote_data_source.dart';

/// Concrete implementation the DI container binds to
/// [CompetitionDetailsRepository]. Same `_guard` shape as
/// `LiveCompetitionRepositoryImpl` / `CompetitionRepositoryImpl`.
class CompetitionDetailsRepositoryImpl implements CompetitionDetailsRepository {
  final CompetitionDetailsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CompetitionDetailsRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, CompetitionDetails>> getCompetitionDetails(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final details = await remoteDataSource.getCompetitionDetails(id);
      return Right(details);
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
