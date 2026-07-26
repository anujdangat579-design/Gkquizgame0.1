import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../data/services/competition_control_socket_service.dart';
import '../../domain/entities/competition_control_snapshot.dart';
import 'competition_control_state.dart';

/// One notifier instance per competition — `.family` keyed by
/// `competitionId`, same reasoning as any per-entity detail screen
/// (mirrors `competitionDetailsNotifierProvider`'s shape, just without
/// that feature's `autoDispose` since an admin flipping between tabs
/// while a competition is live shouldn't drop the socket subscription).
final competitionControlNotifierProvider =
    StateNotifierProvider.family<CompetitionControlNotifier, CompetitionControlState, String>(
  (ref, competitionId) => CompetitionControlNotifier(
    competitionId: competitionId,
    socketService: sl(),
  ),
);

class CompetitionControlNotifier extends StateNotifier<CompetitionControlState> {
  final String competitionId;
  final CompetitionControlSocketService socketService;

  final Random _rng = Random();
  Timer? _ticker;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  // ---------------------------------------------------------------------
  // DEMO-ONLY simulation state. None of this exists once a real backend
  // is wired — it purely lets the dashboard be interacted with today.
  // Delete this whole block plus `_advanceDemo`/`_mockSnapshot` once
  // `loadDashboard` and the socket listener below are hooked up to real
  // endpoints.
  // ---------------------------------------------------------------------
  int _demoNextPlayerSeq = 1;
  int _demoSecondsUntilNextPromotion = 8;

  CompetitionControlNotifier({
    required this.competitionId,
    required this.socketService,
  }) : super(const CompetitionControlState()) {
    loadDashboard();
    _connectLiveUpdates();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Initial load / pull-to-refresh. TODO(backend): replace the mock
  /// snapshot below with a real call, e.g.
  /// `GET /api/admin/competitions/$competitionId/control` returning
  /// `{name, status, playersWaiting, currentMatch, nextMatch, stats,
  /// alerts}`, then map the response onto `CompetitionControlState`
  /// the same way `CompetitionDetailsNotifier` maps its use case result.
  Future<void> loadDashboard() async {
    state = state.copyWith(viewState: CompetitionControlViewState.loading, clearError: true);

    // TODO(backend): await getCompetitionControlSnapshot(competitionId)
    // and `.fold(onError, onSuccess)` here instead of a hard-coded mock.
    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      viewState: CompetitionControlViewState.loaded,
      competitionName: 'Weekend Science Sprint', // TODO(backend): from response
      status: CompetitionControlStatus.paused,
      playersWaiting: 6,
      currentMatch: _demoMatch('m-1001'),
      nextMatch: NextMatchPreview(
        playerA: ControlMatchPlayer(id: 'p-201', name: _demoName()),
        playerB: ControlMatchPlayer(id: 'p-202', name: _demoName()),
        estimatedStartInSeconds: 25,
      ),
      stats: const LiveStats(
        totalPlayers: 42,
        matchesCompleted: 18,
        matchesRunning: 1,
        playersWaiting: 6,
      ),
      alerts: [
        DashboardAlert(
          id: 'a-1',
          type: DashboardAlertType.paymentFailed,
          message: 'Entry fee capture failed for player "Rohit_99"',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        DashboardAlert(
          id: 'a-2',
          type: DashboardAlertType.disconnectedPlayer,
          message: '"Aman_K" disconnected mid-match — auto-forfeit in 30s',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ],
      clearError: true,
    );
  }

  /// Subscribes to `admin:competition:snapshot` for auto-refresh.
  /// TODO(backend): once `CompetitionControlSocketService`'s event
  /// names/payload shape are confirmed, parse `json` into partial state
  /// updates here instead of leaving `_applySocketPayload` a stub. Left
  /// wrapped in try/catch because there's no real server to connect to
  /// yet — a failed connection should fall back to the local ticker
  /// below rather than surface as an error state to the admin.
  Future<void> _connectLiveUpdates() async {
    try {
      final stream = await socketService.watchCompetition(competitionId);
      _socketSubscription = stream.listen(
        _applySocketPayload,
        onError: (e) {
          AppLogger.warning('Competition control socket stream error: $e', tag: 'AdminControl');
          if (mounted) state = state.copyWith(isLiveConnected: false);
        },
      );
      if (mounted) state = state.copyWith(isLiveConnected: true);
    } catch (e) {
      AppLogger.warning('Competition control socket unavailable, using local refresh only: $e', tag: 'AdminControl');
      if (mounted) state = state.copyWith(isLiveConnected: false);
    }
  }

  // TODO(backend): map the confirmed snapshot JSON shape onto
  // `CompetitionControlState` fields (status, currentMatch, nextMatch,
  // stats, playersWaiting, alerts) via `state.copyWith(...)`.
  void _applySocketPayload(Map<String, dynamic> json) {
    AppLogger.info('Competition control snapshot received: ${json.keys}', tag: 'AdminControl');
  }

  // --------------------------- Controls ---------------------------

  Future<void> startCompetition() async {
    if (state.status != CompetitionControlStatus.ended) return;
    await _runAction(CompetitionControlAction.start, () async {
      // TODO(backend): POST /api/admin/competitions/$competitionId/control/start
      state = state.copyWith(status: CompetitionControlStatus.running);
    });
  }

  Future<void> pauseMatchmaking() async {
    if (state.status != CompetitionControlStatus.running) return;
    await _runAction(CompetitionControlAction.pauseMatchmaking, () async {
      // TODO(backend): POST /api/admin/competitions/$competitionId/control/pause-matchmaking
      // Current match is left untouched server-side — only new pairing stops.
      state = state.copyWith(status: CompetitionControlStatus.paused);
    });
  }

  Future<void> resumeMatchmaking() async {
    if (state.status != CompetitionControlStatus.paused) return;
    await _runAction(CompetitionControlAction.resumeMatchmaking, () async {
      // TODO(backend): POST /api/admin/competitions/$competitionId/control/resume-matchmaking
      state = state.copyWith(status: CompetitionControlStatus.running);
    });
  }

  Future<void> endCompetition() async {
    if (state.status == CompetitionControlStatus.ended) return;
    await _runAction(CompetitionControlAction.end, () async {
      // TODO(backend): POST /api/admin/competitions/$competitionId/control/end
      // Server should let any in-progress match finish naturally and
      // simply stop creating new ones — mirrored in `_tick` below by
      // no longer promoting `nextMatch` once `status == ended`.
      state = state.copyWith(status: CompetitionControlStatus.ended, nextMatch: const NextMatchPreview());
    });
  }

  Future<void> _runAction(CompetitionControlAction action, Future<void> Function() body) async {
    state = state.copyWith(pendingAction: action, clearError: true);
    try {
      await Future.delayed(const Duration(milliseconds: 400)); // TODO(backend): remove once a real await replaces this
      await body();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Action failed: $e');
    } finally {
      state = state.copyWith(clearPendingAction: true);
    }
  }

  /// Dismisses an alert locally. TODO(backend): also call
  /// `POST /api/admin/competitions/$competitionId/alerts/$alertId/ack`
  /// so it doesn't resurface next `loadDashboard()`.
  void dismissAlert(String alertId) {
    state = state.copyWith(alerts: state.alerts.where((a) => a.id != alertId).toList());
  }

  // --------------------------- Ticking / demo ---------------------------

  void _tick() {
    if (!mounted) return;

    // Keeps the current-match timer's `elapsed` text moving even though
    // nothing else in state changed — cheap since CurrentMatch keeps
    // `startedAt`, not a counter, as the source of truth.
    if (state.currentMatch != null) {
      state = state.copyWith(); // no-op field changes, just triggers a rebuild
    }

    _advanceDemo();
  }

  /// DEMO ONLY — see block comment above. Simulates matches completing
  /// and the queue refilling so every section of the dashboard has
  /// something to show without a backend. Safe to delete entirely once
  /// `_applySocketPayload` (or a polling fallback) drives real updates.
  void _advanceDemo() {
    if (state.status == CompetitionControlStatus.running && state.playersWaiting > 0 && _rng.nextInt(20) == 0) {
      state = state.copyWith(playersWaiting: state.playersWaiting + 1, stats: LiveStats(
        totalPlayers: state.stats.totalPlayers + 1,
        matchesCompleted: state.stats.matchesCompleted,
        matchesRunning: state.stats.matchesRunning,
        playersWaiting: state.playersWaiting + 1,
      ));
    }

    if (state.currentMatch == null) return;

    _demoSecondsUntilNextPromotion--;
    if (_demoSecondsUntilNextPromotion > 0) return;
    _demoSecondsUntilNextPromotion = 12 + _rng.nextInt(10);

    final matchesCompleted = state.stats.matchesCompleted + 1;

    if (state.status == CompetitionControlStatus.running && state.nextMatch?.isReady == true) {
      final promoted = state.nextMatch!;
      state = state.copyWith(
        currentMatch: CurrentMatch(
          matchId: 'm-${1000 + _demoNextPlayerSeq}',
          playerA: promoted.playerA!,
          playerB: promoted.playerB!,
          startedAt: DateTime.now(),
        ),
        nextMatch: NextMatchPreview(
          playerA: ControlMatchPlayer(id: 'p-${_demoNextPlayerSeq++}', name: _demoName()),
          playerB: state.playersWaiting > 1
              ? ControlMatchPlayer(id: 'p-${_demoNextPlayerSeq++}', name: _demoName())
              : null,
          estimatedStartInSeconds: 20,
        ),
        playersWaiting: (state.playersWaiting - 2).clamp(0, 999),
        stats: LiveStats(
          totalPlayers: state.stats.totalPlayers,
          matchesCompleted: matchesCompleted,
          matchesRunning: 1,
          playersWaiting: (state.playersWaiting - 2).clamp(0, 999),
        ),
      );
    } else {
      // Paused or ended: let the match finish, but don't start another.
      state = state.copyWith(
        clearCurrentMatch: true,
        nextMatch: const NextMatchPreview(),
        stats: LiveStats(
          totalPlayers: state.stats.totalPlayers,
          matchesCompleted: matchesCompleted,
          matchesRunning: 0,
          playersWaiting: state.playersWaiting,
        ),
      );
    }
  }

  CurrentMatch _demoMatch(String id) => CurrentMatch(
        matchId: id,
        playerA: ControlMatchPlayer(id: 'p-101', name: _demoName(), score: 3),
        playerB: ControlMatchPlayer(id: 'p-102', name: _demoName(), score: 2),
        startedAt: DateTime.now().subtract(const Duration(seconds: 37)),
      );

  static const _demoNames = [
    'Rohit_99', 'Aman_K', 'Priya.S', 'Vikram22', 'Neha_R', 'Suresh_B',
    'Anita_M', 'Karan.T', 'Divya_P', 'Rahul_V',
  ];
  String _demoName() => _demoNames[_rng.nextInt(_demoNames.length)];

  @override
  void dispose() {
    _ticker?.cancel();
    _socketSubscription?.cancel();
    socketService.stopWatching(competitionId);
    super.dispose();
  }
}
