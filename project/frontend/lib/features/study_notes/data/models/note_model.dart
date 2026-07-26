import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.price,
    required super.currency,
    super.subject,
    super.categoryId,
    super.description,
    super.thumbnailUrl,
    super.authorName,
    super.pageCount,
    super.rating,
    super.isPurchased,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: (json['id'] ?? json['_id']).toString(),
      title: json['title']?.toString() ?? 'Untitled note',
      subject: json['subject']?.toString(),
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString(),
      description: json['description']?.toString(),
      thumbnailUrl: (json['thumbnailUrl'] ?? json['thumbnail'])?.toString(),
      authorName: (json['authorName'] ?? json['author'])?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      pageCount: (json['pageCount'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      isPurchased: json['isPurchased'] as bool? ?? json['purchased'] as bool? ?? false,
    );
  }
}

/// Paged envelope for `GET ApiConstants.notes` - mirrors
/// `CompetitionPageModel`'s `{ items, pagination: {page, totalPages} }`
/// shape, the same convention every other paged endpoint in this app
/// follows.
class NotePageModel {
  final List<NoteModel> notes;
  final int page;
  final int totalPages;

  const NotePageModel({required this.notes, required this.page, required this.totalPages});

  factory NotePageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['notes'] as List<dynamic>? ?? const [])
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return NotePageModel(
      notes: list,
      page: pagination['page'] as int? ?? 1,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }

  NotesPage toEntity() => NotesPage(notes: notes, page: page, totalPages: totalPages);
}
