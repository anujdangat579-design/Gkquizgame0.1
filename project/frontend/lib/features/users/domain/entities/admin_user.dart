import 'package:equatable/equatable.dart';

/// Account status as controlled from the admin Users screen. Deliberately
/// just these two — there's no "pending"/"deleted" state in scope, since
/// this mirrors `CompetitionStatus`'s enabled/disabled shape rather than
/// inventing a wider lifecycle the backend hasn't confirmed.
enum UserAccountStatus { active, blocked }

/// Pure domain entity for a player account as seen from the admin panel
/// — no JSON, no Dio. Deliberately separate from `UserProfile`
/// (`features/account/domain/entities/user_profile.dart`), which is the
/// *player's own* profile view; this is the *admin's* view of any
/// player, so it carries fields (status, wallet balance, match count)
/// an admin needs to moderate an account that a player would never see
/// about themselves in that shape.
class AdminUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserAccountStatus status;
  final double walletBalance;
  final int totalMatchesPlayed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.status,
    this.walletBalance = 0,
    this.totalMatchesPlayed = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == UserAccountStatus.active;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        status,
        walletBalance,
        totalMatchesPlayed,
        createdAt,
        updatedAt,
      ];
}
