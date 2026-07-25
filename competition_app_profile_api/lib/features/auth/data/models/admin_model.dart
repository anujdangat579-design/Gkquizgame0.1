import '../../domain/entities/admin.dart';

class AdminModel extends Admin {
  const AdminModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      // Accepts either `id` or `_id` since Mongo-backed APIs (like
      // competition-api) commonly return `_id`; adjust here if the auth
      // backend's admin object shape differs from what's assumed below.
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}
