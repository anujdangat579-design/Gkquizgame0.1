import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Every use case in the domain layer implements this so the presentation
/// layer can call them uniformly: `await usecase(params)`.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// For use cases that take no parameters.
class NoParams {
  const NoParams();
}
