import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../entities/match_history_entry.dart';
import '../entities/player_badge.dart';
import '../entities/player_statistics.dart';
import '../entities/purchased_note.dart';
import '../entities/wallet_transaction.dart';

/// Paged result for `getMatchHistory` — same shape as
/// `CompetitionListResult`, since both are paged lists off the same
/// backend envelope (`{items, pagination: {page, limit, total, totalPages}}`).
class MatchHistoryResult {
  final List<MatchHistoryEntry> entries;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const MatchHistoryResult({
    required this.entries,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Paged result for `getTransactions` — mirrors [MatchHistoryResult].
class TransactionsResult {
  final List<WalletTransaction> transactions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const TransactionsResult({
    required this.transactions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Paged result for `getPurchasedNotes` — mirrors [MatchHistoryResult].
class PurchasedNotesResult {
  final List<PurchasedNote> notes;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PurchasedNotesResult({
    required this.notes,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// Contract the domain layer depends on. The data layer provides the
/// concrete implementation (ProfileRepositoryImpl); the presentation
/// layer never talks to it directly, only through use cases. Covers all
/// five profile sub-sections (match history, statistics, badges,
/// transactions, purchased notes) in one repository, the same way
/// `CompetitionRepository` covers every competition action — they're all
/// reads about "this player's own profile", not five unrelated features.
abstract class ProfileRepository {
  Future<Either<Failure, MatchHistoryResult>> getMatchHistory({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  });

  Future<Either<Failure, PlayerStatistics>> getStatistics();

  Future<Either<Failure, List<PlayerBadge>>> getBadges();

  Future<Either<Failure, TransactionsResult>> getTransactions({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
    TransactionType? type,
  });

  Future<Either<Failure, PurchasedNotesResult>> getPurchasedNotes({
    int page = AppConstants.defaultPage,
    int limit = AppConstants.defaultPageLimit,
  });
}
