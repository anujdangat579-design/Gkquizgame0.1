import '../../domain/entities/competition_details.dart';

class DifficultyPricingModel extends DifficultyPricing {
  const DifficultyPricingModel({
    required super.level,
    required super.label,
    required super.entryFee,
  });

  factory DifficultyPricingModel.fromJson(Map<String, dynamic> json) {
    final level = (json['level'] ?? json['key'] ?? '').toString();
    return DifficultyPricingModel(
      level: level,
      label: json['label']?.toString() ?? _titleCase(level),
      entryFee: (json['entryFee'] as num?) ?? 0,
    );
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class CompetitionDetailsModel extends CompetitionDetails {
  const CompetitionDetailsModel({
    required super.id,
    required super.category,
    required super.questionCount,
    required super.timeLabel,
    required super.rules,
    required super.difficulties,
  });

  /// Field names are a best guess (same caveat as `LiveCompetitionModel`
  /// — no confirmed schema for this player-facing endpoint yet).
  /// `difficulties` falls back to the app's previous hardcoded
  /// Normal/Hard/Very Hard (₹10/₹20/₹30) tiers if the backend doesn't
  /// send any, so the screen still has something selectable rather than
  /// an empty pricing list. `rules` falls back to the same generic
  /// rules text `CompetitionDetailsPage` used to hardcode, for the same
  /// reason.
  factory CompetitionDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawDifficulties = json['difficulties'] as List<dynamic>?;
    final rawRules = json['rules'] as List<dynamic>?;

    return CompetitionDetailsModel(
      id: (json['id'] ?? json['_id']).toString(),
      category: (json['category'] ?? json['categoryName'] ?? '').toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 10,
      timeLabel: json['timeLabel']?.toString() ?? _formatTime(json['timeLimitSeconds'] as num?) ?? '10 min',
      rules: rawRules != null && rawRules.isNotEmpty
          ? rawRules.map((e) => e.toString()).toList()
          : _defaultRules,
      difficulties: rawDifficulties != null && rawDifficulties.isNotEmpty
          ? rawDifficulties
              .map((e) => DifficultyPricingModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : _defaultDifficulties,
    );
  }

  static String? _formatTime(num? seconds) {
    if (seconds == null) return null;
    final minutes = (seconds / 60).round();
    return '$minutes min';
  }

  static const List<String> _defaultRules = [
    'Each question has a fixed time limit — unanswered questions are marked incorrect.',
    'Switching apps or minimizing the screen during the competition may result in disqualification.',
    'Entry fees are non-refundable once the competition begins.',
    'Winners are decided by score, then by fastest completion time.',
    'Decisions made by the admin panel on scoring disputes are final.',
  ];

  static const List<DifficultyPricingModel> _defaultDifficulties = [
    DifficultyPricingModel(level: 'normal', label: 'Normal', entryFee: 10),
    DifficultyPricingModel(level: 'hard', label: 'Hard', entryFee: 20),
    DifficultyPricingModel(level: 'veryHard', label: 'Very Hard', entryFee: 30),
  ];
}
