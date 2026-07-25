import '../../domain/entities/purchased_note.dart';

class PurchasedNoteModel extends PurchasedNote {
  const PurchasedNoteModel({
    required super.id,
    required super.title,
    required super.fileUrl,
    required super.price,
    required super.currency,
    required super.purchasedAt,
    super.subject,
    super.thumbnailUrl,
    super.pageCount,
  });

  factory PurchasedNoteModel.fromJson(Map<String, dynamic> json) {
    return PurchasedNoteModel(
      id: (json['id'] ?? json['_id']).toString(),
      title: json['title']?.toString() ?? 'Untitled note',
      subject: json['subject']?.toString(),
      thumbnailUrl: (json['thumbnailUrl'] ?? json['thumbnail'])?.toString(),
      fileUrl: (json['fileUrl'] ?? json['url']).toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      purchasedAt: DateTime.tryParse(json['purchasedAt']?.toString() ?? '') ?? DateTime.now(),
      pageCount: (json['pageCount'] as num?)?.toInt(),
    );
  }
}
