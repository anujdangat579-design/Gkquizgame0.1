import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

// TODO(backend): these two imports assume this feature reuses the same
// core/ singletons as `matchmaking` (shared socket host + auth token).
// Update the paths if the admin dashboard ends up on a different
// realtime host than the player-facing socket.
import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/token_storage.dart';

/// Thin wrapper around `socket_io_client` for the admin Competition
/// Control Dashboard — same role as `MatchmakingSocketService`, kept as
/// a separate class (rather than extending/reusing that one) because
/// the two features subscribe to a different room shape (`competitionId`
/// vs `queueId`) and will very likely end up on different backend
/// namespaces (admin vs player).
///
/// TODO(backend): every event name below is a *guess* mirroring the
/// `matchmaking:*` convention already used by `ApiConstants`
/// (`matchmakingJoinEvent`/`matchmakingLeaveEvent`/`matchmakingUpdateEvent`).
/// Confirm the real event names with the backend team and move these
/// out of this file into `ApiConstants` (as
/// `adminCompetitionJoinEvent` etc.) once confirmed, the same way the
/// matchmaking ones live there today.
class CompetitionControlSocketService {
  // TODO(backend): confirm/replace with ApiConstants.adminCompetitionJoinEvent.
  static const String _joinEvent = 'admin:competition:join';
  static const String _leaveEvent = 'admin:competition:leave';

  // TODO(backend): confirm whether the server sends one combined
  // "snapshot" event per update (assumed here) or separate events per
  // section (e.g. `admin:competition:match-update`,
  // `admin:competition:stats-update`, `admin:competition:alert`). A
  // combined snapshot is simpler for this dashboard since every section
  // updates in lockstep anyway; split this into per-section listeners
  // in `watchCompetition` below if the backend disagrees.
  static const String _snapshotEvent = 'admin:competition:snapshot';

  final TokenStorage _tokenStorage;

  socket_io.Socket? _socket;
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  CompetitionControlSocketService(this._tokenStorage);

  /// Subscribes to real-time control-panel updates for `competitionId`.
  /// Returns a broadcast stream of raw JSON snapshots — left un-parsed
  /// here (unlike `MatchmakingSocketService`, which parses into a
  /// model) since the exact snapshot shape is still TODO(backend);
  /// `CompetitionControlNotifier` is where that JSON should get mapped
  /// onto `CompetitionControlState` once the schema is confirmed.
  Future<Stream<Map<String, dynamic>>> watchCompetition(String competitionId) async {
    final existing = _controllers[competitionId];
    if (existing != null) return existing.stream;

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[competitionId] = controller;

    final socket = await _ensureConnected();

    void onSnapshot(dynamic payload) {
      if (payload is! Map) return;
      final json = Map<String, dynamic>.from(payload);
      // Defensive filter in case the backend broadcasts more broadly
      // than the per-competition room this joins below — mirrors
      // MatchmakingSocketService's same defensive check.
      final eventCompetitionId = (json['competitionId'] ?? json['competition_id'])?.toString();
      if (eventCompetitionId != null && eventCompetitionId != competitionId) return;

      controller.add(json);
    }

    socket.on(_snapshotEvent, onSnapshot);
    socket.emit(_joinEvent, {'competitionId': competitionId});

    controller.onCancel = () => socket.off(_snapshotEvent, onSnapshot);

    return controller.stream;
  }

  /// Unsubscribes from `competitionId` — call from the dashboard's
  /// `dispose()` so the admin leaving the screen doesn't keep the
  /// server pushing updates nobody's listening to.
  void stopWatching(String competitionId) {
    _socket?.emit(_leaveEvent, {'competitionId': competitionId});
    final controller = _controllers.remove(competitionId);
    controller?.close();
  }

  Future<socket_io.Socket> _ensureConnected() async {
    final socket = _socket;
    if (socket != null && socket.connected) return socket;
    if (socket != null) {
      socket.connect();
      return socket;
    }

    final token = await _tokenStorage.getToken();
    final newSocket = socket_io.io(
      ApiConstants.socketUrl,
      socket_io.OptionBuilder()
          .setPath(ApiConstants.socketPath)
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    newSocket.onConnect((_) => AppLogger.info('Competition control socket connected', tag: 'AdminControl'));
    newSocket.onDisconnect((_) => AppLogger.info('Competition control socket disconnected', tag: 'AdminControl'));
    newSocket.onConnectError((e) => AppLogger.warning('Competition control socket connect error: $e', tag: 'AdminControl'));
    newSocket.onError((e) => AppLogger.warning('Competition control socket error: $e', tag: 'AdminControl'));

    _socket = newSocket;
    return newSocket;
  }

  /// Tears down the shared socket entirely — call at logout/app
  /// shutdown, not between dashboard visits (use `stopWatching` then).
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _socket?.dispose();
    _socket = null;
  }
}
