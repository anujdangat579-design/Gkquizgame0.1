import 'package:equatable/equatable.dart';

/// Server's acknowledgement of a submitted winner feedback, from
/// `ApiConstants.matchFeedback`. Deliberately thin — the caller
/// (`WinnerFeedbackPage`) only needs to know the submission landed, not
/// echo back the rating/comment it already has locally.
class FeedbackResult extends Equatable {
  final String? feedbackId;
  final bool submitted;

  const FeedbackResult({this.feedbackId, this.submitted = true});

  @override
  List<Object?> get props => [feedbackId, submitted];
}
