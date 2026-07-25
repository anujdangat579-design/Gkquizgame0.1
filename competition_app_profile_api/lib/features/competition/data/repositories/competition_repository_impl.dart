import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/competition.dart';
import '../../domain/repositories/competition_repository.dart';
import '../datasources/competition_remote_data_source.dart';

/// Concrete implementation the DI container binds to [CompetitionRepository].
/// Checks connectivity, calls the remote data source, and converts any
/// thrown exception into a typed [Failure] via Dartz's Either.
class CompetitionRepositoryImpl implements CompetitionRepository {
  final CompetitionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CompetitionRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, CompetitionListResult>> getCompetitions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    String? search,
  }) {
    return _guard(() async {
      final page_ = await remoteDataSource.getCompetitions(page: page, limit: limit, search: search);
      return CompetitionListResult(
        competitions: page_.competitions,
        page: page_.page,
        limit: page_.limit,
        total: page_.total,
        totalPages: page_.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, Competition>> getCompetitionById(String id) {
    return _guard(() => remoteDataSource.getCompetitionById(id));
  }

  @override
  Future<Either<Failure, Competition>> createCompetition({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _guard(() => remoteDataSource.createCompetition(
          name: name,
          description: description,
          startDate: startDate,
          endDate: endDate,
        ));
  }

  @override
  Future<Either<Failure, Competition>> updateCompetition({
    required String id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _guard(() => remoteDataSource.updateCompetition(
          id: id,
          name: name,
          description: description,
          startDate: startDate,
          endDate: endDate,
        ));
  }

  @override
  Future<Either<Failure, Competition>> setCompetitionStatus({
    required String id,
    required bool enabled,
  }) {
    return _guard(() => remoteDataSource.setStatus(id: id, enabled: enabled));
  }

  @override
  Future<Either<Failure, void>> deleteCompetition(String id) {
    return _guard(() => remoteDataSource.deleteCompetition(id));
  }

  /// Shared "check connectivity, run the call, map exceptions" wrapper so
  /// every method above stays a one-liner.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await action();
      return Right(result);
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
