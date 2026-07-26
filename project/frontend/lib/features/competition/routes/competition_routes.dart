import 'package:go_router/go_router.dart';

import '../domain/entities/competition.dart';
import '../presentation/pages/competition_details_page.dart';
import '../presentation/pages/competition_form_page.dart';
import '../presentation/pages/competition_list_page.dart';
import '../presentation/pages/live_competitions_page.dart';
import '../presentation/pages/opponent_found_page.dart' show OpponentFoundArgs, OpponentFoundPage, QueuePlayer;
import '../presentation/pages/waiting_queue_page.dart' show WaitingQueueArgs, WaitingQueuePage;

/// Route paths + GoRoute definitions owned by this feature. The app-level
/// router (core/routes/app_router.dart) merges these `routes` into the
/// single GoRouter instead of listing every page itself.
class CompetitionRoutes {
  CompetitionRoutes._();

  static const String list = '/competitions';
  static const String form = 'form'; // nested under `list`: /competitions/form
  static const String live = 'live'; // nested under `list`: /competitions/live
  static const String details = 'details/:id'; // nested under `live`: /competitions/live/details/:id
  static const String queue = 'queue'; // nested under `details`: /competitions/live/details/:id/queue
  static const String opponentFound = 'opponent-found'; // nested under `details`: /competitions/live/details/:id/opponent-found

  static String detailsPath(String id) => '$list/$live/details/$id';
  static String queuePath(String id) => '${detailsPath(id)}/$queue';
  static String opponentFoundPath(String id) => '${detailsPath(id)}/$opponentFound';

  static List<RouteBase> get routes => [
        GoRoute(
          path: list,
          name: 'competitions',
          builder: (context, state) => const CompetitionListPage(),
          routes: [
            GoRoute(
              path: form,
              name: 'competitionForm',
              // Editing passes the Competition via `extra`; creating passes
              // nothing, so `state.extra` is null and the form starts blank.
              builder: (context, state) => CompetitionFormPage(
                competition: state.extra as Competition?,
              ),
            ),
            GoRoute(
              path: live,
              name: 'liveCompetitions',
              // Optional category filter passed as a query param, e.g.
              // `context.push('${CompetitionRoutes.list}/${CompetitionRoutes.live}?category=Science')`.
              builder: (context, state) => LiveCompetitionsPage(
                category: state.uri.queryParameters['category'],
              ),
              routes: [
                GoRoute(
                  path: details,
                  name: 'competitionDetails',
                  // `extra` carries the category as a fallback app-bar title
                  // while the real details load; see CompetitionDetailsPage's
                  // doc comment.
                  builder: (context, state) => CompetitionDetailsPage(
                    competitionId: state.pathParameters['id']!,
                    initialCategory: state.extra as String?,
                  ),
                  routes: [
                    GoRoute(
                      path: queue,
                      name: 'competitionQueue',
                      // Pushed by CompetitionDetailsPage once the entry
                      // fee is paid, the join is confirmed, and the
                      // player has been placed in the matchmaking pool;
                      // `extra` is the WaitingQueueArgs carrying the
                      // real queue entry (see WaitingQueuePage's doc
                      // comment).
                      builder: (context, state) {
                        final args = state.extra as WaitingQueueArgs?;
                        return WaitingQueuePage(
                          competitionId: state.pathParameters['id']!,
                          category: args?.category ?? 'Competition',
                          queueId: args?.queueId,
                          initialQueuePosition: args?.initialQueuePosition ?? 4,
                          initialPlayersAhead: args?.initialPlayersAhead ?? 3,
                          initialEstimatedWaitSeconds: args?.initialEstimatedWaitSeconds ?? 45,
                        );
                      },
                    ),
                    GoRoute(
                      path: opponentFound,
                      name: 'opponentFound',
                      // Pushed by WaitingQueuePage (replacing itself in
                      // the stack) the moment the matchmaking feed
                      // reports `MatchmakingStatus.matched`; `extra` is
                      // the OpponentFoundArgs built from that entry
                      // (see WaitingQueuePage._navigateToOpponentFound).
                      builder: (context, state) {
                        final args = state.extra as OpponentFoundArgs?;
                        return OpponentFoundPage(
                          you: args?.you ?? const QueuePlayer(name: 'You'),
                          opponent: args?.opponent ?? const QueuePlayer(name: 'Opponent'),
                          category: args?.category ?? 'Competition',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];
}
