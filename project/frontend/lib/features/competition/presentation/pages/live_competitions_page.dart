import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/live_competition.dart';
import '../providers/live_competition_notifier.dart';
import '../providers/live_competition_state.dart';
import '../widgets/live_competition_card.dart';
import '../../routes/competition_routes.dart';

/// Player-facing screen listing currently live/joinable quiz
/// competitions, backed by `liveCompetitionNotifierProvider` ->
/// `GetLiveCompetitions` -> `GET ApiConstants.liveCompetitions` (see that
/// constant's doc comment for the endpoint-path caveat). Same
/// load-on-init / pull-to-refresh / loading-error-empty shape as
/// `CompetitionListPage` and `CategoryGrid`.
///
/// Tapping "Join now" on a card pushes `CompetitionDetailsPage` (the
/// difficulty-selection/confirm screen), passing the competition's id so
/// it can load its own richer `CompetitionDetails` — this page's
/// `LiveCompetition` rows intentionally stay list-shaped rather than
/// carrying rules/per-difficulty pricing too.
///
/// Not wired into `MainShellPage`'s bottom nav — this admin app has no
/// player-facing tab yet (its three tabs are Dashboard/Competitions/
/// Account, all admin screens). Add a route/tab for it, or push it from
/// `CategoryGrid`'s `onCategoryTap`, once the app grows a player-facing
/// entry point.
class LiveCompetitionsPage extends ConsumerStatefulWidget {
  final String? category;

  const LiveCompetitionsPage({super.key, this.category});

  @override
  ConsumerState<LiveCompetitionsPage> createState() => _LiveCompetitionsPageState();
}

class _LiveCompetitionsPageState extends ConsumerState<LiveCompetitionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveCompetitionNotifierProvider.notifier).loadLiveCompetitions(category: widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveCompetitionNotifierProvider);
    final notifier = ref.read(liveCompetitionNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category ?? 'Live competitions')),
      body: Builder(
        builder: (context) {
          if (state.viewState == LiveCompetitionViewState.loading && state.liveCompetitions.isEmpty) {
            return const LoadingIndicator();
          }

          if (state.viewState == LiveCompetitionViewState.error && state.liveCompetitions.isEmpty) {
            return ErrorState(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => notifier.loadLiveCompetitions(category: widget.category),
            );
          }

          if (state.liveCompetitions.isEmpty) {
            return const EmptyState(
              message: 'No live competitions right now. Check back soon.',
              icon: Icons.emoji_events_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifier.loadLiveCompetitions(category: widget.category),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.liveCompetitions.length,
              itemBuilder: (context, index) {
                final competition = state.liveCompetitions[index];
                return LiveCompetitionCard(
                  category: competition.category,
                  entryFee: competition.entryFee,
                  questionCount: competition.questionCount,
                  timeLabel: competition.timeLabel,
                  playersWaiting: competition.playersWaiting,
                  isLive: competition.isLive,
                  onJoin: () => _handleJoin(competition),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleJoin(LiveCompetition competition) {
    context.push(CompetitionRoutes.detailsPath(competition.id), extra: competition.category);
  }
}
