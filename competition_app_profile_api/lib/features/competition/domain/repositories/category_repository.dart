import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/category.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (CategoryRepositoryImpl); the presentation
/// layer never talks to it directly, only through use cases. Mirrors
/// CompetitionRepository's shape.
abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories();
}
