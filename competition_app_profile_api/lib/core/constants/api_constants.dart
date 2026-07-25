import '../config/env_config.dart';

class ApiConstants {
  ApiConstants._();

  // Sourced from EnvConfig, which resolves this per-environment via
  // env/{dev,staging,prod}.json — see EnvConfig for details.
  static const String baseUrl = EnvConfig.apiBaseUrl;

  // Assumed to follow the same `/api/admin/...` convention as
  // `competitions` below — update this if the auth backend uses a
  // different path (e.g. no `/auth` segment, or lives on its own host).
  static const String login = '/api/admin/auth/login';

  // Assumed to be the currently-authenticated admin's own record (no id
  // in the path — the backend identifies "who" from the bearer token,
  // same as every other request DioClient sends). Update this if your
  // backend instead expects e.g. `/api/admin/me` or `/api/admin/:id`.
  static const String profile = '/api/admin/profile';

  static const String competitions = '/api/admin/competitions';

  // Assumed sibling of `competitions` — categories aren't part of the
  // Competition schema (see CategoryGrid's original doc comment), so
  // this is a guess at a standalone endpoint rather than something
  // derived from `competitions`. Update if your backend nests these
  // differently (e.g. `/api/admin/competitions/categories`).
  static const String categories = '/api/admin/categories';
  static String competitionById(String id) => '$competitions/$id';
  static String enableCompetition(String id) => '$competitions/$id/enable';
  static String disableCompetition(String id) => '$competitions/$id/disable';

  // Assumed sibling of `competitions` — same `/api/admin/...` CRUD
  // convention, for the admin "manage player accounts" screen. Not part
  // of the confirmed WIRING.md scope (only `competitions` was), so this
  // is a best guess; update if the backend nests users differently.
  static const String users = '/api/admin/users';
  static String userById(String id) => '$users/$id';
  static String blockUser(String id) => '$users/$id/block';
  static String unblockUser(String id) => '$users/$id/unblock';

  // Assumed sibling of `users`/`competitions` — the admin quiz question
  // bank (create/edit/delete questions, each with a correct-answer
  // index, unlike the player-facing `matchQuestions` payload which never
  // includes one). Same unconfirmed-schema caveat as `users` above.
  static const String questions = '/api/admin/questions';
  static String questionById(String id) => '$questions/$id';

  // Assumed sibling of `competitions` — a single aggregate snapshot for
  // the admin Dashboard's stat cards (see `DashboardPage`'s doc comment:
  // it currently derives totals from whichever page of `competitions`
  // happens to be loaded, which is only correct until results paginate).
  // Same unconfirmed-schema caveat as `users`/`questions`.
  static const String dashboardStatistics = '/api/admin/dashboard/statistics';

  // Assumed player-facing endpoint for the "join a live quiz" flow
  // (`LiveCompetitionCard`) — this wasn't part of the admin CRUD scope
  // in competition-api.zip's WIRING.md (no player-join/leaderboard
  // endpoints there), so there's no confirmed path for it yet. Update
  // this once the real backend route for live/joinable competitions is
  // known (e.g. it may live outside `/api/admin` entirely, on a
  // `/api/player/...` prefix, since admin and player are different
  // audiences hitting the same backend).
  static const String liveCompetitions = '/api/player/competitions/live';

  // Assumed sibling of `liveCompetitions` for the "before you join"
  // details screen (`CompetitionDetailsPage`) — same unconfirmed-schema
  // caveat as that constant. Update once the real path is known (it may
  // not be nested under `live` at all, e.g. `/api/player/competitions/:id`
  // regardless of whether that competition is currently live).
  static String competitionDetails(String id) => '/api/player/competitions/$id';

  // TODO(backend): confirm the real path + response schema for order
  // creation, then update this constant and PaymentOrderModel.fromJson.
  // Assumed sibling of the player-facing endpoints above, for the
  // payment flow gating `CompetitionDetailsPage`'s "Join competition"
  // button. Cashfree order creation *requires* the merchant secret key,
  // so it can only happen server-side — this endpoint sends just what
  // the backend needs to build the Cashfree order (competitionId +
  // chosen difficulty) and relies on the bearer token DioClient already
  // attaches to identify the player (and their name/email/phone for
  // Cashfree's `customer_details`). Expected response: `{orderId,
  // paymentSessionId, orderAmount, currency}` — see
  // PaymentOrderModel.fromJson. No confirmed schema yet.
  static const String paymentOrders = '/api/player/payments/orders';

  // TODO(backend): confirm the real path + response schema for order
  // status/verification, then update this constant and
  // PaymentVerificationModel.fromJson.
  // Assumed sibling of `paymentOrders`, polled/called once the Cashfree
  // checkout SDK returns control to the app. The SDK's `onVerify`
  // callback only means checkout *finished* — never the actual payment
  // outcome, which must be confirmed against Cashfree from the backend,
  // not trusted from the client (see CashfreeCheckoutService's doc
  // comment). Also assumed to be where the backend finalizes the
  // player's entry into the competition once the order is `PAID`, so a
  // successful response here means both "payment confirmed" and
  // "joined" (see PaymentVerificationModel.fromJson / `joined`).
  static String paymentOrderStatus(String orderId) => '$paymentOrders/$orderId';

  // Assumed sibling of the player-facing endpoints above — called right
  // after `paymentOrderStatus` confirms `joined: true` (see
  // JoinCompetitionNotifier), to place the now-paid player into the
  // live matchmaking pool for `competitionId`. `orderId` is sent so the
  // backend can tie the queue entry back to the specific paid entry
  // (useful if a player somehow has more than one `joined` order for
  // the same competition). Expected response: `{queueId, status,
  // queuePosition, playersAhead, estimatedWaitSeconds}` — see
  // MatchmakingEntryModel.fromJson. No confirmed schema yet; update
  // once the real backend route is known.
  static const String matchmakingQueue = '/api/player/matchmaking/queue';

  // TODO(backend): confirm the real path + response schema for both
  // polling queue status (GET) and leaving the queue (DELETE), then
  // update this constant and MatchmakingEntryModel.fromJson.
  // Assumed sibling of `matchmakingQueue`. GET is polled by
  // `WaitingQueuePage` (via `GetMatchmakingStatus`) to drive the real
  // status ring/position/wait-time; DELETE is used by that page's
  // "Cancel and leave queue" action while `status` is still `queued`.
  static String matchmakingQueueEntry(String queueId) => '$matchmakingQueue/$queueId';

  // TODO(backend): confirm the real path + response schema for fetching
  // a match's question set, then update this constant and
  // QuestionModel.fromJson.
  // Assumed sibling of `matchmakingQueueEntry` — called once
  // `OpponentFoundPage`'s countdown hits zero and `QuizPage` needs the
  // actual question set for this match, keyed by the same `queueId`
  // that identified the player's matchmaking entry (server already
  // knows the paired opponent, category, and difficulty from that
  // entry, so no other params are needed). Deliberately does NOT
  // return which option is correct — see `QuestionModel.fromJson` —
  // since that would let a client-side inspection reveal answers
  // before they're submitted; scoring happens server-side against
  // `submitAnswer`.
  static String matchQuestions(String queueId) => '${matchmakingQueueEntry(queueId)}/questions';

  // TODO(backend): confirm the real path + response schema for
  // submitting an answer, then update this constant and
  // AnswerResultModel.fromJson.
  // Assumed sibling of `matchQuestions`. Request body:
  // `{questionId, selectedOptionIndex}` (`selectedOptionIndex` is
  // `null` on a timeout auto-submit) — sent by `QuizPage._handleNext`/
  // `_handleAutoSubmit` via `QuizNotifier.submitAnswer`. Expected
  // response: `{isCorrect, correctOptionIndex, yourScore,
  // opponentScore}`, all best-effort/optional — see
  // AnswerResultModel.fromJson.
  static String submitAnswer(String queueId) => '${matchmakingQueueEntry(queueId)}/answer';

  // TODO(backend): confirm the real path + response schema for the
  // final match outcome, then update this constant and MatchResultModel.
  // Assumed sibling of `submitAnswer`/`matchQuestions`. Called once
  // `QuizPage` has submitted every question (see `_goToCompletedThenResult`)
  // to fetch the settled outcome — final scores, correctness count, and
  // (optionally) a per-question breakdown — rather than trusting the
  // client's own running tally, since scoring happens server-side.
  // Expected response: `{matchId, you: {name, photoUrl, rankLabel},
  // opponent: {...}, yourScore, opponentScore, correctAnswers,
  // totalQuestions, timeTakenSeconds, category, questions: [...]}`, all
  // best-effort/optional except the scores — see MatchResultModel.fromJson.
  static String matchResult(String queueId) => '${matchmakingQueueEntry(queueId)}/result';

  // TODO(backend): confirm the real path + response schema for winner
  // feedback submission, then update this constant and FeedbackResultModel.
  // Assumed a player-facing endpoint keyed by `matchId` (not `queueId` —
  // `WinnerFeedbackPage` only ever receives `matchId`, forwarded from
  // `MatchResult.matchId`, since feedback is about a settled match, not
  // a still-live queue entry). Request body:
  // `{rating, comment, reportedOpponent, reportReason}` — see
  // `WinnerFeedbackNotifier.submit`. Expected response: `{feedbackId,
  // submitted}`, both best-effort/optional — see
  // `FeedbackResultModel.fromJson`. No confirmed schema yet.
  static String matchFeedback(String matchId) => '/api/player/matches/$matchId/feedback';

  // TODO(backend): confirm the real path + response schema for the
  // leaderboard, then update this constant and LeaderboardBoardModel.
  // Assumed a player-facing endpoint, filtered via a `range` query
  // param (`today`/`weekly`/`all_time` — see `LeaderboardRange.apiValue`)
  // rather than three separate paths, since it's the same ranking list
  // just windowed differently. Expected response: `{entries: [{rank,
  // player: {name, photoUrl, rankLabel}, points, isCurrentUser}],
  // currentUserEntry}`, where `currentUserEntry` is only sent when the
  // player isn't already inside `entries` (e.g. outside the top N) —
  // see `LeaderboardBoardModel.fromJson`. No confirmed schema yet.
  static const String leaderboard = '/api/player/leaderboard';

  // TODO(backend): confirm the real path + response schema for match
  // history, then update this constant and MatchHistoryPageModel.fromJson.
  // Assumed sibling of the other player-facing endpoints above (not part
  // of the confirmed admin CRUD scope either) — a paged list of the
  // player's own settled matches, most recent first. Expected response:
  // `{matches: [...], pagination: {page, limit, total, totalPages}}`,
  // mirroring `CompetitionPageModel`'s envelope shape since both are
  // paged lists off the same backend. Query params: `page`, `limit`.
  static const String profileMatchHistory = '/api/player/profile/matches';

  // TODO(backend): confirm the real path + response schema for the
  // player's aggregate stats, then update this constant and
  // PlayerStatisticsModel.fromJson.
  // Assumed sibling of `profileMatchHistory` — a single settled snapshot
  // (matches played/won/lost/drawn, accuracy, streaks, points, optional
  // per-category breakdown) rather than something the client derives by
  // summing `profileMatchHistory` itself, since the backend has the full
  // history (not just whatever page is loaded) to compute it from.
  static const String profileStatistics = '/api/player/profile/statistics';

  // TODO(backend): confirm the real path + response schema for badges,
  // then update this constant and PlayerBadgeModel.fromJson.
  // Assumed sibling of `profileStatistics` — the full badge catalog for
  // this player (earned *and* locked/in-progress), not just earned ones,
  // so `BadgesPage` can show locked badges as goals rather than only
  // ever showing what's already been unlocked. Expected response:
  // `{badges: [...]}`.
  static const String profileBadges = '/api/player/profile/badges';

  // TODO(backend): confirm the real path + response schema for the
  // player's wallet/transaction ledger, then update this constant and
  // WalletTransactionPageModel.fromJson.
  // Assumed sibling of `profileMatchHistory` — a paged ledger covering
  // every money movement on the player's account (entry fees, prize
  // payouts, refunds, wallet top-ups, note purchases), not just
  // Cashfree's own order history, since `paymentOrders`/`paymentOrderStatus`
  // only cover order creation/verification for a single competition entry,
  // not the player's full running ledger. Query params: `page`, `limit`,
  // optional `type`. Expected response: same paged envelope as
  // `profileMatchHistory`.
  static const String profileTransactions = '/api/player/profile/transactions';

  // TODO(backend): confirm the real path + response schema for notes the
  // player has purchased, then update this constant and
  // PurchasedNoteModel.fromJson.
  // Assumed sibling of `profileTransactions` — a paged list of study
  // notes the player has already bought (title, subject, file/thumbnail
  // URLs, price paid, purchase date), separate from the `notePurchase`
  // transactions themselves so `PurchasedNotesPage` doesn't have to
  // reconstruct "what was bought" by cross-referencing the ledger.
  // Query params: `page`, `limit`. Expected response: same paged
  // envelope as `profileMatchHistory`.
  static const String profilePurchasedNotes = '/api/player/profile/notes';

  // TODO(backend): confirm the real path + response schema for note
  // categories, then update this constant and NoteCategoryModel.fromJson.
  // Assumed player-facing sibling of `liveCompetitions`/`categories` -
  // the Study Notes module's own category list (subjects like "Science",
  // "History"), separate from the admin quiz `categories` above since
  // notes and competitions aren't necessarily grouped the same way.
  static const String noteCategories = '/api/player/notes/categories';

  // TODO(backend): confirm the real path + response schema for the
  // notes catalog, then update this constant and NotePageModel.fromJson.
  // Assumed sibling of `noteCategories` - a paged, optionally
  // category/search-filtered list of study notes for sale, mirroring
  // `competitions`'s paged envelope shape. Query params: `page`,
  // `limit`, optional `category`, optional `search`.
  static const String notes = '/api/player/notes';

  // Assumed sibling of `notes` - a single note's full detail (used by
  // `NoteDetailsPage`), including whether the current player already
  // owns it (`isPurchased`) so the page can show "Buy" vs "Open in My
  // Library" without a second round trip.
  static String noteDetails(String id) => '$notes/$id';

  // TODO(backend): confirm the real path + response schema for note
  // order creation, then update this constant and NoteOrderModel.fromJson.
  // Assumed sibling of `paymentOrders`, for the "Buy Notes" flow gating
  // `NoteDetailsPage`'s buy button. Cashfree order creation requires the
  // merchant secret key, so - same as `paymentOrders` - this can only
  // happen server-side; the client sends just `noteId` and relies on
  // the bearer token to identify the player. Expected response:
  // `{orderId, paymentSessionId, orderAmount, currency}` - see
  // NoteOrderModel.fromJson. No confirmed schema yet.
  static const String noteOrders = '/api/player/notes/orders';

  // TODO(backend): confirm the real path + response schema for note
  // order status/verification, then update this constant and
  // NotePurchaseVerificationModel.fromJson.
  // Assumed sibling of `noteOrders`, called once the Cashfree checkout
  // SDK returns control to the app (same caveat as
  // `paymentOrderStatus`: checkout *finishing* isn't the same as
  // payment *succeeding*). Also assumed to be where the backend
  // finalizes the note purchase once the order is `PAID`, so a
  // successful response here means both "payment confirmed" and
  // "unlocked" - see NotePurchaseVerificationModel.fromJson / `purchased`.
  static String noteOrderStatus(String orderId) => '$noteOrders/$orderId';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // TODO(backend): confirm the real Socket.IO path/namespace and event
  // names below, then update MatchmakingSocketService accordingly.
  // Assumed to be served by the same backend as `baseUrl` (Socket.IO's
  // default `/socket.io` path on that host) rather than a separate
  // realtime service — update `socketUrl`/`socketPath` if that's wrong.
  static const String socketUrl = baseUrl;
  static const String socketPath = '/socket.io';

  // Client -> server: sent once connected, to subscribe to updates for
  // one queue entry (payload: `{queueId}`). Assumed to scope the
  // subscription server-side (e.g. joining a Socket.IO "room" named
  // after `queueId`) so this client only receives events for its own
  // entry, not every player's.
  static const String matchmakingJoinEvent = 'matchmaking:join';

  // Client -> server: sent when the player leaves the queue via the UI,
  // mirroring the `matchmakingQueueEntry` DELETE call so the server can
  // stop pushing updates for this entry immediately rather than waiting
  // for the socket to disconnect.
  static const String matchmakingLeaveEvent = 'matchmaking:leave';

  // Server -> client: pushed on every queue-state change for a
  // subscribed `queueId`. Payload shape assumed to match
  // `GetMatchmakingStatus`'s REST response — see
  // MatchmakingEntryModel.fromJson.
  static const String matchmakingUpdateEvent = 'matchmaking:update';
}
