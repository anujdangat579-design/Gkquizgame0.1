import '../../domain/entities/player_badge.dart';

class PlayerBadgeModel extends PlayerBadge {
  const PlayerBadgeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.tier,
    required super.isEarned,
    super.iconUrl,
    super.earnedAt,
    super.progressCurrent,
    super.progressTarget,
  });

  factory PlayerBadgeModel.fromJson(Map<String, dynamic> json) {
    return PlayerBadgeModel(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? 'Badge',
      description: json['description']?.toString() ?? '',
      tier: _tierFrom(json['tier']),
      isEarned: json['isEarned'] as bool? ?? json['earned'] as bool? ?? false,
      iconUrl: (json['iconUrl'] ?? json['icon'])?.toString(),
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt'].toString()) : null,
      progressCurrent: (json['progressCurrent'] as num?)?.toInt(),
      progressTarget: (json['progressTarget'] as num?)?.toInt(),
    );
  }

  static BadgeTier _tierFrom(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'silver':
        return BadgeTier.silver;
      case 'gold':
        return BadgeTier.gold;
      case 'platinum':
        return BadgeTier.platinum;
      default:
        return BadgeTier.bronze;
    }
  }
}
