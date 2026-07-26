import 'package:equatable/equatable.dart';

/// Pure domain entity for the logged-in admin — no JSON, no Dio.
/// Mirrors the `admin` object returned alongside the token by
/// `POST /api/admin/auth/login`.
class Admin extends Equatable {
  final String id;
  final String name;
  final String email;

  const Admin({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}
