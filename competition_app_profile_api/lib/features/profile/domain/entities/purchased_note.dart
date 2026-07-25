import 'package:equatable/equatable.dart';

/// One row from `ApiConstants.profilePurchasedNotes`. Backs
/// `PurchasedNotesPage`'s list — study notes the player has already
/// bought, separate from the `notePurchase` rows in
/// [WalletTransaction]'s ledger (this is "what was bought", not
/// "what was paid").
class PurchasedNote extends Equatable {
  final String id;
  final String title;
  final String? subject;
  final String? thumbnailUrl;

  /// Where the actual note content lives — deliberately not opened
  /// in-app yet (no PDF/file viewer wired up), so `PurchasedNotesPage`
  /// only surfaces this as metadata for now.
  final String fileUrl;

  final double price;
  final String currency;
  final DateTime purchasedAt;

  /// Null when the backend doesn't send a page count for this note.
  final int? pageCount;

  const PurchasedNote({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.price,
    required this.currency,
    required this.purchasedAt,
    this.subject,
    this.thumbnailUrl,
    this.pageCount,
  });

  @override
  List<Object?> get props =>
      [id, title, subject, thumbnailUrl, fileUrl, price, currency, purchasedAt, pageCount];
}
