import '../../domain/entities/admin_question.dart';

/// Data-layer model. Knows how to (de)serialize JSON; the domain layer
/// never sees this class, only the [AdminQuestion] entity it extends.
/// Mirrors `CompetitionModel`'s shape/conventions. Unlike the
/// player-facing `QuestionModel` (`features/competition/data/models/`),
/// this one both reads and writes `correctOptionIndex` — the admin
/// panel is exactly where that field is allowed to exist client-side.
class AdminQuestionModel extends AdminQuestion {
  const AdminQuestionModel({
    required super.id,
    required super.categoryId,
    required super.text,
    required super.options,
    required super.correctOptionIndex,
    super.difficulty,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] ?? json['choices']) as List<dynamic>? ?? const [];
    return AdminQuestionModel(
      id: (json['id'] ?? json['_id']).toString(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? json['category']).toString(),
      text: (json['text'] ?? json['question'] ?? '').toString(),
      options: rawOptions.map((e) => e.toString()).toList(),
      correctOptionIndex:
          ((json['correctOptionIndex'] ?? json['correct_option_index']) as num?)?.toInt() ?? 0,
      difficulty: _difficultyFromJson(json['difficulty']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static List<AdminQuestionModel> listFromJson(dynamic data) {
    final List<dynamic> raw = data is Map<String, dynamic>
        ? (data['questions'] as List<dynamic>? ?? const [])
        : (data as List<dynamic>? ?? const []);
    return raw.map((e) => AdminQuestionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static QuestionDifficulty _difficultyFromJson(String? value) {
    switch (value) {
      case 'hard':
        return QuestionDifficulty.hard;
      case 'easy':
        return QuestionDifficulty.easy;
      default:
        return QuestionDifficulty.medium;
    }
  }

  static String _difficultyToJson(QuestionDifficulty value) {
    switch (value) {
      case QuestionDifficulty.hard:
        return 'hard';
      case QuestionDifficulty.easy:
        return 'easy';
      case QuestionDifficulty.medium:
        return 'medium';
    }
  }

  static Map<String, dynamic> toCreateJson({
    required String categoryId,
    required String text,
    required List<String> options,
    required int correctOptionIndex,
    required QuestionDifficulty difficulty,
  }) {
    return {
      'categoryId': categoryId,
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'difficulty': _difficultyToJson(difficulty),
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? categoryId,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
    QuestionDifficulty? difficulty,
  }) {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      if (text != null) 'text': text,
      if (options != null) 'options': options,
      if (correctOptionIndex != null) 'correctOptionIndex': correctOptionIndex,
      if (difficulty != null) 'difficulty': _difficultyToJson(difficulty),
    };
  }
}
