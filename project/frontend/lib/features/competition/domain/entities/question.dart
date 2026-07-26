import 'package:equatable/equatable.dart';

/// Pure domain entity for a single quiz question served for a live
/// match. Mirrors `QuizPage`'s old UI-only `QuizQuestion` (text + four
/// options), plus a stable `id` so an answer submission can reference
/// exactly which question it's for.
///
/// Deliberately carries no "correct option" field — see
/// `ApiConstants.matchQuestions`'s doc comment for why the backend
/// shouldn't send that to the client before scoring.
class Question extends Equatable {
  final String id;
  final String text;
  final List<String> options;

  const Question({
    required this.id,
    required this.text,
    required this.options,
  });

  @override
  List<Object?> get props => [id, text, options];
}
