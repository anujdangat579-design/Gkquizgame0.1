import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/player_badge.dart';
import '../../domain/entities/player_statistics.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Concrete implementation the DI container binds to [ProfileRepository].
/// Checks connectivity, calls the remote data source, and converts any
/// thrown exception into a typed [Failure] — same `_guard` shape as
/// `CompetitionRepositoryImpl`/`AccountRepositoryImpl`.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, MatchHistoryResult>> getMatchHistory({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  }) {
    return _guard(() async {
      final result = await remoteDataSource.getMatchHistory(page: page, limit: limit);
      return MatchHistoryResult(
        entries: result.entries,
        page: result.page,
        limit: result.limit,
        total: result.total,
        totalPages: result.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, PlayerStatistics>> getStatistics() {
    return _guard(() => remoteDataSource.getStatistics());
  }

  @override
  Future<Either<Failure, List<PlayerBadge>>> getBadges() {
    return _guard(() => remoteDataSource.getBadges());
  }

  @override
  Future<Either<Failure, TransactionsResult>> getTransactions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    TransactionType? type,
  }) {
    return _guard(() async {
      final result = await remoteDataSource.getTransactions(page: page, limit: limit, type: type);
      return TransactionsResult(
        transactions: result.transactions,
        page: result.page,
        limit: result.limit,
        total: result.total,
        totalPages: result.totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, PurchasedNotesResult>> getPurchasedNotes({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  }) {
    return _guard(() async {
      final result = await remoteDataSource.getPurchasedNotes(page: page, limit: limit);
      return PurchasedNotesResult(
        notes: result.notes,
        page: result.page,
        limit: result.limit,
        total: result.total,
        totalPages: result.totalPages,
      );
    });
  }

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
