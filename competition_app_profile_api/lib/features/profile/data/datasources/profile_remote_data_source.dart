import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../models/match_history_entry_model.dart';
import '../models/player_badge_model.dart';
import '../models/player_statistics_model.dart';
import '../models/purchased_note_model.dart';
import '../models/wallet_transaction_model.dart';

/// Envelope for `ApiConstants.profileMatchHistory` — same
/// `{items, pagination: {...}}` shape as `CompetitionPageModel`.
class MatchHistoryPageModel {
  final List<MatchHistoryEntryModel> entries;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const MatchHistoryPageModel({
    required this.entries,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory MatchHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['matches'] as List<dynamic>? ?? const [])
        .map((e) => MatchHistoryEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return MatchHistoryPageModel(
      entries: list,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? list.length,
      total: pagination['total'] as int? ?? list.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

/// Envelope for `ApiConstants.profileTransactions` — mirrors
/// [MatchHistoryPageModel].
class TransactionsPageModel {
  final List<WalletTransactionModel> transactions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const TransactionsPageModel({
    required this.transactions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory TransactionsPageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List<dynamic>? ?? const [])
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return TransactionsPageModel(
      transactions: list,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? list.length,
      total: pagination['total'] as int? ?? list.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

/// Envelope for `ApiConstants.profilePurchasedNotes` — mirrors
/// [MatchHistoryPageModel].
class PurchasedNotesPageModel {
  final List<PurchasedNoteModel> notes;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PurchasedNotesPageModel({
    required this.notes,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PurchasedNotesPageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['notes'] as List<dynamic>? ?? const [])
        .map((e) => PurchasedNoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PurchasedNotesPageModel(
      notes: list,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? list.length,
      total: pagination['total'] as int? ?? list.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

/// Talks directly to the assumed `/api/player/profile/...` endpoints —
/// see each `ApiConstants.profile*` constant's doc comment for the
/// no-confirmed-schema caveat. Throws
/// [ServerException]/[NetworkException]/[UnauthorizedException] (via
/// [DioClient]), which the repository catches and converts to Failures.
abstract class ProfileRemoteDataSource {
  Future<MatchHistoryPageModel> getMatchHistory({int page, int limit});
  Future<PlayerStatisticsModel> getStatistics();
  Future<List<PlayerBadgeModel>> getBadges();
  Future<TransactionsPageModel> getTransactions({int page, int limit, TransactionType? type});
  Future<PurchasedNotesPageModel> getPurchasedNotes({int page, int limit});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient client;

  ProfileRemoteDataSourceImpl(this.client);

  @override
  Future<MatchHistoryPageModel> getMatchHistory({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  }) async {
    final response = await client.get(
      ApiConstants.profileMatchHistory,
      queryParameters: {'page': page, 'limit': limit},
    );
    return MatchHistoryPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PlayerStatisticsModel> getStatistics() async {
    final response = await client.get(ApiConstants.profileStatistics);
    return PlayerStatisticsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<PlayerBadgeModel>> getBadges() async {
    final response = await client.get(ApiConstants.profileBadges);
    final data = response.data as Map<String, dynamic>;
    final list = data['badges'] as List<dynamic>? ?? const [];
    return list.map((e) => PlayerBadgeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TransactionsPageModel> getTransactions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    TransactionType? type,
  }) async {
    final response = await client.get(
      ApiConstants.profileTransactions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (type != null) 'type': type.name,
      },
    );
    return TransactionsPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PurchasedNotesPageModel> getPurchasedNotes({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  }) async {
    final response = await client.get(
      ApiConstants.profilePurchasedNotes,
      queryParameters: {'page': page, 'limit': limit},
    );
    return PurchasedNotesPageModel.fromJson(response.data as Map<String, dynamic>);
  }
}
