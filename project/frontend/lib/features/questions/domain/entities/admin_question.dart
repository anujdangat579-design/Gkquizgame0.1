import 'package:equatable/equatable.dart';

enum QuestionDifficulty { easy, medium, hard }

/// Pure domain entity for a question bank entry as managed from the
/// admin panel — no JSON, no Dio. Deliberately separate from
/// `Question` (`features/competition/domain/entities/question.dart`),
/// which is the *player-facing* shape served during a live match and
/// never carries a correct-answer index (see that file's doc comment);
/// this is the *admin's* authoring view of the same underlying
/// question, so it does carry one, plus the category/difficulty
/// metadata an author needs but a player never sees.
class AdminQuestion extends Equatable {
  final String id;
  final String categoryId;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final QuestionDifficulty difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminQuestion({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    this.difficulty = QuestionDifficulty.medium,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        text,
        options,
        correctOptionIndex,
        difficulty,
        createdAt,
        updatedAt,
      ];
}
