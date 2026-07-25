import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/feedback_result.dart';

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (FeedbackRepositoryImpl); the presentation
/// layer never talks to it directly, only through `SubmitWinnerFeedback`.
abstract class FeedbackRepository {
  /// Submits a winner's post-match feedback for `matchId` — see
  /// `ApiConstants.matchFeedback`'s doc comment for the request shape.
  /// `reportReason` is only meaningful when `reportedOpponent` is true.
  Future<Either<Failure, FeedbackResult>> submitFeedback({
    required String matchId,
    required int rating,
    String? comment,
    required bool reportedOpponent,
    String? reportReason,
  });
}
