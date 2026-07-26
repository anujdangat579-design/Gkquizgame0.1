/// Tracks the offset between this device's clock and the backend's,
/// derived from the standard HTTP `Date` response header that every
/// request already gets back — no dedicated time-sync endpoint needed.
///
/// [DioClient] updates this on every response/error via [recordServerDate].
/// Anything that needs to agree with the server's idea of "now" (see
/// `QuizPage`'s per-question timer, synced against a server-issued match
/// start time) should read [now] instead of `DateTime.now()` directly —
/// a device with a wrong clock would otherwise desync its countdown from
/// the opponent's.
class ServerClock {
  ServerClock._();
  static final ServerClock instance = ServerClock._();

  Duration _offset = Duration.zero;
  bool _hasSynced = false;

  /// Whether at least one server `Date` header has been recorded yet.
  /// [now] still returns a sensible value before this is true (falling
  /// back to the device's own clock, offset zero) — this is only for
  /// callers that want to know whether that fallback is currently active.
  bool get hasSynced => _hasSynced;

  /// Updates the estimated offset from one HTTP round trip.
  ///
  /// [requestSentAt] and [responseReceivedAt] bound how long the
  /// request was in flight; halving that bounds when, within the round
  /// trip, the server most likely stamped [serverDate], so the estimate
  /// doesn't treat the header as if it arrived at the device instantly.
  void recordServerDate(
    DateTime serverDate, {
    required DateTime requestSentAt,
    required DateTime responseReceivedAt,
  }) {
    final roundTrip = responseReceivedAt.difference(requestSentAt);
    if (roundTrip.isNegative) return; // clock stepped backwards mid-request — skip this sample
    final estimatedServerNowAtReceipt = serverDate.add(roundTrip ~/ 2);
    _offset = estimatedServerNowAtReceipt.difference(responseReceivedAt);
    _hasSynced = true;
  }

  /// Best current estimate of the server's clock, in UTC.
  DateTime now() => DateTime.now().toUtc().add(_offset);
}
