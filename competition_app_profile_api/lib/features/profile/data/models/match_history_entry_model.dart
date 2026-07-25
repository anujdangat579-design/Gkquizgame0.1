import '../../domain/entities/match_history_entry.dart';

class MatchHistoryOpponentModel extends MatchHistoryOpponent {
  const MatchHistoryOpponentModel({required super.name, super.photoUrl});

  factory MatchHistoryOpponentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MatchHistoryOpponentModel(name: 'Unknown');
    return MatchHistoryOpponentModel(
      name: json['name']?.toString() ?? 'Unknown',
      photoUrl: (json['photoUrl'] ?? json['photo'] ?? json['avatarUrl'])?.toString(),
    );
  }
}

class MatchHistoryEntryModel extends MatchHistoryEntry {
  const MatchHistoryEntryModel({
    required super.matchId,
    required super.opponent,
    required super.category,
    required super.outcome,
    required super.yourScore,
    required super.opponentScore,
    required super.correctAnswers,
    required super.totalQuestions,
    required super.pointsEarned,
    required super.playedAt,
  });

  factory MatchHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return MatchHistoryEntryModel(
      matchId: (json['matchId'] ?? json['id'] ?? json['_id']).toString(),
      opponent: MatchHistoryOpponentModel.fromJson(json['opponent'] as Map<String, dynamic>?),
      category: json['category']?.toString() ?? 'General',
      outcome: _outcomeFrom(json['outcome'] ?? json['result']),
      yourScore: (json['yourScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      playedAt: DateTime.tryParse(json['playedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static MatchOutcome _outcomeFrom(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'win':
      case 'won':
        return MatchOutcome.win;
      case 'loss':
      case 'lost':
        return MatchOutcome.loss;
      default:
        return MatchOutcome.draw;
    }
  }
}
