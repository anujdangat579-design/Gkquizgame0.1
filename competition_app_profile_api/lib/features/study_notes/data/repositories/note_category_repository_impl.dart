import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/note_category.dart';
import '../../domain/repositories/note_category_repository.dart';
import '../datasources/note_category_remote_data_source.dart';

/// Concrete implementation the DI container binds to
/// [NoteCategoryRepository]. Same `_guard` shape as
/// `CategoryRepositoryImpl`.
class NoteCategoryRepositoryImpl implements NoteCategoryRepository {
  final NoteCategoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NoteCategoryRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<NoteCategory>>> getNoteCategories() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final categories = await remoteDataSource.getNoteCategories();
      return Right(categories);
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
