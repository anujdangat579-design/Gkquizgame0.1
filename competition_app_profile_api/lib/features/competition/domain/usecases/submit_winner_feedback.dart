import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/feedback_result.dart';
import '../repositories/feedback_repository.dart';

class SubmitWinnerFeedbackParams extends Equatable {
  final String matchId;
  final int rating;
  final String? comment;
  final bool reportedOpponent;
  final String? reportReason;

  const SubmitWinnerFeedbackParams({
    required this.matchId,
    required this.rating,
    this.comment,
    required this.reportedOpponent,
    this.reportReason,
  });

  @override
  List<Object?> get props => [matchId, rating, comment, reportedOpponent, reportReason];
}

class SubmitWinnerFeedback implements UseCase<FeedbackResult, SubmitWinnerFeedbackParams> {
  final FeedbackRepository repository;

  SubmitWinnerFeedback(this.repository);

  @override
  Future<Either<Failure, FeedbackResult>> call(SubmitWinnerFeedbackParams params) {
    return repository.submitFeedback(
      matchId: params.matchId,
      rating: params.rating,
      comment: params.comment,
      reportedOpponent: params.reportedOpponent,
      reportReason: params.reportReason,
    );
  }
}
