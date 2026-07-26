import 'package:equatable/equatable.dart';

/// One study note/PDF listed for sale (or already owned) in the Study
/// Notes module. Deliberately separate from `PurchasedNote` (profile
/// feature) — that entity is "what was bought" (purchase-ledger shape:
/// `purchasedAt`, price *paid*); this one is "what's browsable"
/// (catalog shape: `description`, `isPurchased` flag, current price).
/// A note that appears here and has `isPurchased == true` is the same
/// underlying record `PurchasedNote` represents once bought.
class Note extends Equatable {
  final String id;
  final String title;
  final String? subject;
  final String? categoryId;
  final String? description;
  final String? thumbnailUrl;
  final String? authorName;
  final double price;
  final String currency;
  final int? pageCount;

  /// 0.0-5.0, null when the backend doesn't send a rating yet.
  final double? rating;

  /// Whether the current player already owns this note — drives
  /// `NoteDetailsPage`'s "Buy" vs "Open in My Library" button.
  final bool isPurchased;

  const Note({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    this.subject,
    this.categoryId,
    this.description,
    this.thumbnailUrl,
    this.authorName,
    this.pageCount,
    this.rating,
    this.isPurchased = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subject,
        categoryId,
        description,
        thumbnailUrl,
        authorName,
        price,
        currency,
        pageCount,
        rating,
        isPurchased,
      ];
}
