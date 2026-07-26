import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.username,
    super.avatarUrl,
    super.dateOfBirth,
    super.gender,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      // Accepts either `id` or `_id`, same as AdminModel — Mongo-backed
      // APIs (like competition-api) commonly return `_id`.
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'])?.toString(),
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'].toString()) : null,
      gender: json['gender']?.toString(),
    );
  }

  /// Only includes fields the caller actually set — a `PATCH` shouldn't
  /// clobber fields the user isn't editing back to `null`. Mirrors
  /// `CompetitionModel.toUpdateJson`'s reasoning.
  static Map<String, dynamic> toUpdateJson({
    String? name,
    String? username,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    return {
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      if (gender != null) 'gender': gender,
    };
  }
}
