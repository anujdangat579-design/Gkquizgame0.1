import 'package:equatable/equatable.dart';

/// One difficulty tier's pricing/label for a competition — e.g. Normal /
/// Hard / Very Hard, each with its own entry fee. Previously
/// `CompetitionDetailsPage`'s private `_Difficulty` enum hardcoded these
/// (₹10/₹20/₹30 for normal/hard/veryHard); now they come from the
/// backend so pricing can change without a client release.
class DifficultyPricing extends Equatable {
  final String level; // stable key, e.g. 'normal' | 'hard' | 'veryHard'
  final String label; // display label, e.g. 'Very Hard'
  final num entryFee;

  const DifficultyPricing({
    required this.level,
    required this.label,
    required this.entryFee,
  });

  @override
  List<Object?> get props => [level, label, entryFee];
}

/// Pure domain entity for the "before you join" details screen
/// (`CompetitionDetailsPage`) — richer than `LiveCompetition` (the list
/// row on `LiveCompetitionsPage`), since it carries per-difficulty
/// pricing and the rules text a player needs before confirming.
class CompetitionDetails extends Equatable {
  final String id;
  final String category;
  final int questionCount;
  final String timeLabel;
  final List<String> rules;
  final List<DifficultyPricing> difficulties;

  const CompetitionDetails({
    required this.id,
    required this.category,
    required this.questionCount,
    required this.timeLabel,
    required this.rules,
    required this.difficulties,
  });

  @override
  List<Object?> get props => [id, category, questionCount, timeLabel, rules, difficulties];
}
