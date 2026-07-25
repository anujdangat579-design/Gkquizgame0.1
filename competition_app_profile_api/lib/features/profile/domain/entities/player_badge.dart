import 'package:equatable/equatable.dart';

/// Visual/rarity tier a badge belongs to — purely cosmetic (drives
/// `BadgesPage`'s color per tile), the backend still decides
/// earned/locked and progress independently of this.
enum BadgeTier { bronze, silver, gold, platinum }

/// One entry from the player's full badge catalog, from
/// `ApiConstants.profileBadges`. Named `PlayerBadge` rather than
/// `Badge` to avoid colliding with Flutter's own `Badge` widget.
///
/// The catalog includes locked/in-progress badges alongside earned
/// ones (see [isEarned]) so `BadgesPage` can show what's still to
/// achieve, not just what's already unlocked.
class PlayerBadge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final BadgeTier tier;
  final bool isEarned;

  /// Null when [isEarned] is false, or when the backend doesn't track
  /// an exact unlock moment for this badge.
  final DateTime? earnedAt;

  /// Current progress toward [progressTarget] for a still-locked badge
  /// (e.g. "7" of "10 wins"). Both null when this badge doesn't track
  /// incremental progress at all (e.g. a one-shot achievement).
  final int? progressCurrent;
  final int? progressTarget;

  const PlayerBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.isEarned,
    this.iconUrl,
    this.earnedAt,
    this.progressCurrent,
    this.progressTarget,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        tier,
        isEarned,
        earnedAt,
        progressCurrent,
        progressTarget,
      ];
}
