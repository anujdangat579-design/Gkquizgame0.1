import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconKey,
    super.subtitle,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? '',
      // Backend field name assumed to be `icon`; falls back to `slug`
      // so an unrelated-but-close key still resolves to something
      // instead of always hitting CategoryGrid's default icon.
      iconKey: (json['icon'] ?? json['slug'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
    );
  }

  /// Accepts either a bare JSON array or `{ "categories": [...] }` —
  /// the exact shape wasn't known ahead of time (see the comment on
  /// `ApiConstants.categories`), so this tries the common wrapped form
  /// first and falls back to treating the payload itself as the list.
  static List<CategoryModel> listFromJson(dynamic data) {
    final List<dynamic> raw = data is Map<String, dynamic>
        ? (data['categories'] as List<dynamic>? ?? const [])
        : (data as List<dynamic>? ?? const []);
    return raw.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
