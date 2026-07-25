import 'package:equatable/equatable.dart';

/// Pure domain entity for the logged-in admin's profile — no JSON, no
/// Dio. Superset of `auth`'s `Admin` (id/name/email): this is the fuller
/// record the "Account" tab reads, matching the fields
/// `CompleteProfilePage` collects at signup (name, username, avatar,
/// date of birth, gender) plus email/id from the account itself.
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
  });

  @override
  List<Object?> get props => [id, name, email, username, avatarUrl, dateOfBirth, gender];
}
