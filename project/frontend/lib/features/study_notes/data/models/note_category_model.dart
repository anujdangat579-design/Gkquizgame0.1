import '../../domain/entities/note_category.dart';

class NoteCategoryModel extends NoteCategory {
  const NoteCategoryModel({
    required super.id,
    required super.name,
    required super.iconKey,
    super.noteCount,
  });

  factory NoteCategoryModel.fromJson(Map<String, dynamic> json) {
    return NoteCategoryModel(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? '',
      iconKey: (json['icon'] ?? json['slug'] ?? '').toString(),
      noteCount: (json['noteCount'] ?? json['count']) is num
          ? ((json['noteCount'] ?? json['count']) as num).toInt()
          : null,
    );
  }

  /// Accepts either a bare JSON array or `{ "categories": [...] }` -
  /// same defensive shape as `CategoryModel.listFromJson`, since the
  /// exact envelope isn't confirmed yet either.
  static List<NoteCategoryModel> listFromJson(dynamic data) {
    final List<dynamic> raw = data is Map<String, dynamic>
        ? (data['categories'] as List<dynamic>? ?? const [])
        : (data as List<dynamic>? ?? const []);
    return raw.map((e) => NoteCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
