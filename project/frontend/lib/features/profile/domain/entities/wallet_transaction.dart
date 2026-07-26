import 'package:equatable/equatable.dart';

/// What kind of money movement a ledger row represents. Deliberately
/// broader than just Cashfree entry-fee orders (`payment` feature only
/// covers *creating*/*verifying* one competition entry) — this is the
/// player's full running ledger.
enum TransactionType { entryFee, prizePayout, refund, walletTopup, notePurchase, other }

enum TransactionStatus { pending, completed, failed }

/// One row from `ApiConstants.profileTransactions`. Backs
/// `TransactionsPage`'s list — every money movement on the player's
/// account, most recent first.
class WalletTransaction extends Equatable {
  final String id;
  final TransactionType type;
  final TransactionStatus status;

  /// Signed in the currency's minor-agnostic display unit (e.g. rupees,
  /// not paise) — positive for money coming in (prize payouts, wallet
  /// top-ups), negative for money going out (entry fees, note
  /// purchases), so `TransactionsPage` can color/prefix it directly
  /// without re-deriving sign from [type].
  final double amount;
  final String currency;
  final String description;
  final DateTime createdAt;

  /// Optional link back to whatever this transaction is *about* — a
  /// competition id for an entry fee/prize payout, an order id for a
  /// Cashfree-backed row, a note id for a purchase. Null when the
  /// backend doesn't send one or it doesn't apply (e.g. a wallet top-up).
  final String? referenceId;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    this.referenceId,
  });

  @override
  List<Object?> get props =>
      [id, type, status, amount, currency, description, createdAt, referenceId];
}
