import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.type,
    required super.status,
    required super.amount,
    required super.currency,
    required super.description,
    required super.createdAt,
    super.referenceId,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: (json['id'] ?? json['_id']).toString(),
      type: _typeFrom(json['type']),
      status: _statusFrom(json['status']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      referenceId: (json['referenceId'] ?? json['orderId'] ?? json['competitionId'])?.toString(),
    );
  }

  static TransactionType _typeFrom(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'entryfee':
      case 'entry_fee':
        return TransactionType.entryFee;
      case 'prizepayout':
      case 'prize_payout':
        return TransactionType.prizePayout;
      case 'refund':
        return TransactionType.refund;
      case 'wallettopup':
      case 'wallet_topup':
      case 'topup':
        return TransactionType.walletTopup;
      case 'notepurchase':
      case 'note_purchase':
        return TransactionType.notePurchase;
      default:
        return TransactionType.other;
    }
  }

  static TransactionStatus _statusFrom(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.completed;
    }
  }
}
