import '../../domain/entities/admin_user.dart';

/// Data-layer model. Knows how to (de)serialize JSON; the domain layer
/// never sees this class, only the [AdminUser] entity it extends.
/// Mirrors `CompetitionModel`'s shape/conventions.
class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.status,
    super.walletBalance,
    super.totalMatchesPlayed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      // Accepts either `id` or `_id`, same Mongo-backed-API caveat as
      // `AdminModel.fromJson`.
      id: (json['id'] ?? json['_id']).toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      status: (json['status'] as String?) == 'blocked'
          ? UserAccountStatus.blocked
          : UserAccountStatus.active,
      walletBalance: ((json['walletBalance'] ?? json['wallet_balance']) as num?)?.toDouble() ?? 0,
      totalMatchesPlayed:
          ((json['totalMatchesPlayed'] ?? json['total_matches_played']) as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String name,
    required String email,
    String? phone,
    String? password,
  }) {
    return {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (password != null) 'password': password,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? name,
    String? email,
    String? phone,
  }) {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }
}
