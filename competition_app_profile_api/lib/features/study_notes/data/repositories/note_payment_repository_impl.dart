import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/note_order.dart';
import '../../domain/entities/note_purchase_verification.dart';
import '../../domain/repositories/note_payment_repository.dart';
import '../datasources/note_payment_remote_data_source.dart';

/// Mirrors `PaymentRepositoryImpl`'s shape exactly.
class NotePaymentRepositoryImpl implements NotePaymentRepository {
  final NotePaymentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotePaymentRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, NoteOrder>> createOrder(String noteId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final order = await remoteDataSource.createOrder(noteId);
      return Right(order);
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

  @override
  Future<Either<Failure, NotePurchaseVerification>> verifyPayment(String orderId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final verification = await remoteDataSource.verifyPayment(orderId);
      return Right(verification);
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
