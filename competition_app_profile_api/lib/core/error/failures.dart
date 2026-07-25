import 'package:equatable/equatable.dart';

/// Base class for all failures surfaced to the presentation layer.
/// Repositories convert exceptions into Failures so the UI never
/// has to deal with raw Dio/network errors.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired, please log in again']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load cached data']);
}
