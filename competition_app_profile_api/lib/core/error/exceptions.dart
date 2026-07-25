/// Exceptions thrown by data sources. These get caught in the repository
/// implementation and mapped to a [Failure] before reaching the domain layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({this.message = 'Server error', this.statusCode});
}

class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'No internet connection']);
}

class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException([this.message = 'Unauthorized']);
}
