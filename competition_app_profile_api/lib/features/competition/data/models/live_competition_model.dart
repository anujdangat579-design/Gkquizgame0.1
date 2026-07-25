import '../../domain/entities/live_competition.dart';

class LiveCompetitionModel extends LiveCompetition {
  const LiveCompetitionModel({
    required super.id,
    required super.category,
    required super.entryFee,
    required super.questionCount,
    required super.timeLabel,
    required super.playersWaiting,
    required super.isLive,
  });

  /// Field names are a best guess mirroring the shape of the other
  /// player-facing fields on `LiveCompetitionCard` (see that widget's
  /// doc comment) — there's no swagger/WIRING.md for a player/live
  /// endpoint the way there is for the admin `competitions` one.
  /// `timeLabel` falls back to formatting `timeLimitSeconds` if the
  /// backend sends seconds instead of a ready-made label; update the
  /// field names/formatting here if your backend differs.
  factory LiveCompetitionModel.fromJson(Map<String, dynamic> json) {
    return LiveCompetitionModel(
      id: (json['id'] ?? json['_id']).toString(),
      category: (json['category'] ?? json['categoryName'] ?? '').toString(),
      entryFee: (json['entryFee'] as num?) ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      timeLabel: json['timeLabel']?.toString() ?? _formatTime(json['timeLimitSeconds'] as num?),
      playersWaiting: (json['playersWaiting'] as num?)?.toInt() ?? 0,
      // Accepts either a ready-made bool or a string status
      // (`"live"`/`"open"` vs `"closed"`/`"full"`) since which shape the
      // backend uses wasn't known ahead of time.
      isLive: json['isLive'] as bool? ?? _statusIsLive(json['status']?.toString()),
    );
  }

  /// Accepts either a bare JSON array or `{ "competitions": [...] }` /
  /// `{ "liveCompetitions": [...] }`, matching `CategoryModel.listFromJson`'s
  /// defensive shape for the same reason: the exact envelope isn't known.
  static List<LiveCompetitionModel> listFromJson(dynamic data) {
    final List<dynamic> raw = data is Map<String, dynamic>
        ? (data['liveCompetitions'] as List<dynamic>? ??
            data['competitions'] as List<dynamic>? ??
            const [])
        : (data as List<dynamic>? ?? const []);
    return raw.map((e) => LiveCompetitionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String _formatTime(num? seconds) {
    if (seconds == null) return '';
    final minutes = (seconds / 60).round();
    return '$minutes min';
  }

  static bool _statusIsLive(String? status) {
    if (status == null) return false;
    return status.toLowerCase() == 'live' || status.toLowerCase() == 'open';
  }
}
