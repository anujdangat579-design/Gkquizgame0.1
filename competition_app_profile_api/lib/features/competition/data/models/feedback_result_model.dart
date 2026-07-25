import '../../domain/entities/feedback_result.dart';

class FeedbackResultModel extends FeedbackResult {
  const FeedbackResultModel({super.feedbackId, super.submitted});

  /// Field names are a best guess — no confirmed schema yet for
  /// `ApiConstants.matchFeedback` (see that constant's doc comment).
  /// `submitted` defaults to true: a 2xx response with no body (or no
  /// `submitted` field at all) still means the POST succeeded, same as
  /// `PaymentVerificationModel`'s pattern for a bare-success ack.
  factory FeedbackResultModel.fromJson(Map<String, dynamic> json) {
    return FeedbackResultModel(
      feedbackId: (json['feedbackId'] ?? json['id'])?.toString(),
      submitted: json['submitted'] as bool? ?? true,
    );
  }
}
