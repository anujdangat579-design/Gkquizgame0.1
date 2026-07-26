import '../../domain/entities/matchmaking_entry.dart';

class MatchmakingEntryModel extends MatchmakingEntry {
  const MatchmakingEntryModel({
    required super.queueId,
    required super.status,
    required super.queuePosition,
    required super.playersAhead,
    required super.estimatedWaitSeconds,
    super.opponentId,
    super.opponentName,
    super.opponentPhotoUrl,
    super.opponentRankLabel,
    super.yourName,
    super.yourPhotoUrl,
    super.yourRankLabel,
  });

  /// Field names are a best guess (same unconfirmed-schema caveat as
  /// `PaymentOrderModel` — no confirmed schema for this endpoint yet,
  /// see `ApiConstants.matchmakingQueue`). The opponent/self fields are
  /// only expected to be populated once `status` is `MATCHED`; they're
  /// read defensively (all optional) so an entry missing them still
  /// parses fine at earlier statuses.
  factory MatchmakingEntryModel.fromJson(Map<String, dynamic> json) {
    final opponent = (json['opponent'] ?? json['opponentUser']) as Map?;
    final you = (json['you'] ?? json['self'] ?? json['player']) as Map?;

    return MatchmakingEntryModel(
      queueId: (json['queueId'] ?? json['queue_id'] ?? '').toString(),
      status: _parseStatus((json['status'] ?? '').toString().toUpperCase()),
      queuePosition: (json['queuePosition'] as num?)?.toInt() ??
          (json['queue_position'] as num?)?.toInt() ??
          0,
      playersAhead: (json['playersAhead'] as num?)?.toInt() ??
          (json['players_ahead'] as num?)?.toInt() ??
          0,
      estimatedWaitSeconds: (json['estimatedWaitSeconds'] as num?)?.toInt() ??
          (json['estimated_wait_seconds'] as num?)?.toInt() ??
          0,
      opponentId: (json['opponentId'] ?? json['opponent_id'] ?? opponent?['id'])?.toString(),
      opponentName: (json['opponentName'] ?? json['opponent_name'] ?? opponent?['name'])?.toString(),
      opponentPhotoUrl: (json['opponentPhotoUrl'] ??
              json['opponent_photo_url'] ??
              json['opponentAvatarUrl'] ??
              opponent?['photoUrl'] ??
              opponent?['avatarUrl'])
          ?.toString(),
      opponentRankLabel: (json['opponentRankLabel'] ??
              json['opponent_rank_label'] ??
              json['opponentRank'] ??
              opponent?['rankLabel'] ??
              opponent?['rank'])
          ?.toString(),
      yourName: (json['yourName'] ?? json['your_name'] ?? you?['name'])?.toString(),
      yourPhotoUrl: (json['yourPhotoUrl'] ??
              json['your_photo_url'] ??
              json['yourAvatarUrl'] ??
              you?['photoUrl'] ??
              you?['avatarUrl'])
          ?.toString(),
      yourRankLabel: (json['yourRankLabel'] ??
              json['your_rank_label'] ??
              json['yourRank'] ??
              you?['rankLabel'] ??
              you?['rank'])
          ?.toString(),
    );
  }

  static MatchmakingStatus _parseStatus(String rawStatus) {
    switch (rawStatus) {
      case 'MATCHING':
        return MatchmakingStatus.matching;
      case 'MATCHED':
        return MatchmakingStatus.matched;
      case 'CANCELLED':
        return MatchmakingStatus.cancelled;
      case 'QUEUED':
      default:
        return MatchmakingStatus.queued;
    }
  }
}
