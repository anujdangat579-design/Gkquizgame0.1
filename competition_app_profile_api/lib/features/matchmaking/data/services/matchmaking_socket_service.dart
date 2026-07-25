import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/matchmaking_entry_model.dart';

/// Thin wrapper around `socket_io_client` so the rest of the app never
/// touches the plugin's callback-based `.on(...)` API directly — mirrors
/// `DioClient`'s role for Dio and `CashfreeCheckoutService`'s role for
/// the Cashfree SDK.
///
/// One socket connection is shared for the whole app (lazy singleton via
/// DI, same as `DioClient`), but subscriptions are scoped per `queueId`:
/// `watchQueue` emits `matchmakingJoinEvent` to subscribe and returns a
/// broadcast [Stream] filtered to that entry's updates; `stopWatching`
/// emits `matchmakingLeaveEvent` and closes that stream. The underlying
/// socket itself is left connected between queue entries (reconnecting
/// it per screen would throw away socket.io's own reconnection/backoff
/// handling for no benefit) and is only torn down by `dispose()`.
///
/// **Server-side prerequisite this depends on:** the backend must scope
/// `matchmakingUpdateEvent` payloads to the subscribing client (e.g. via
/// a Socket.IO "room" per `queueId`) — see `ApiConstants.matchmakingJoinEvent`'s
/// doc comment. This class also defensively filters incoming payloads by
/// `queueId` in case the backend broadcasts more broadly than that.
class MatchmakingSocketService {
  final TokenStorage _tokenStorage;

  socket_io.Socket? _socket;
  final Map<String, StreamController<MatchmakingEntryModel>> _controllers = {};
  // Keyed alongside `_controllers` so `stopWatching` can explicitly
  // unregister the socket-level listener rather than depending on
  // `controller.onCancel` having already fired first — the latter only
  // happens if the caller cancels its stream subscription *before*
  // calling `stopWatching`. Every current call site does that, but
  // relying on that ordering was fragile: a future caller that calls
  // `stopWatching` first would otherwise leak an `onUpdate` closure on
  // the shared socket.
  final Map<String, void Function(dynamic)> _handlers = {};

  MatchmakingSocketService(this._tokenStorage);

  /// Subscribes to real-time updates for `queueId`. Connects the
  /// underlying socket on first use (or reuses it if another queue
  /// entry is already being watched). The returned stream closes itself
  /// when [stopWatching] is called for the same `queueId`; callers
  /// should still cancel their subscription in `dispose`/`initState`
  /// teardown as usual.
  Future<Stream<MatchmakingEntryModel>> watchQueue(String queueId) async {
    final existing = _controllers[queueId];
    if (existing != null) return existing.stream;

    final controller = StreamController<MatchmakingEntryModel>.broadcast();
    _controllers[queueId] = controller;

    final socket = await _ensureConnected();

    void onUpdate(dynamic payload) {
      if (payload is! Map) return;
      final json = Map<String, dynamic>.from(payload);
      // Defensive filter — see class doc comment on why this shouldn't
      // be necessary if the backend scopes the event server-side.
      final eventQueueId = (json['queueId'] ?? json['queue_id'])?.toString();
      if (eventQueueId != null && eventQueueId != queueId) return;

      try {
        controller.add(MatchmakingEntryModel.fromJson(json));
      } catch (e) {
        AppLogger.warning('Malformed ${ApiConstants.matchmakingUpdateEvent} payload: $e', tag: 'Matchmaking');
      }
    }

    socket.on(ApiConstants.matchmakingUpdateEvent, onUpdate);
    socket.emit(ApiConstants.matchmakingJoinEvent, {'queueId': queueId});
    _handlers[queueId] = onUpdate;

    controller.onCancel = () {
      socket.off(ApiConstants.matchmakingUpdateEvent, onUpdate);
      _handlers.remove(queueId);
    };

    return controller.stream;
  }

  /// Unsubscribes from `queueId` (e.g. the player left the queue or
  /// left `WaitingQueuePage`). Safe to call even if `watchQueue` was
  /// never called for this id.
  void stopWatching(String queueId) {
    _socket?.emit(ApiConstants.matchmakingLeaveEvent, {'queueId': queueId});
    final handler = _handlers.remove(queueId);
    if (handler != null) {
      _socket?.off(ApiConstants.matchmakingUpdateEvent, handler);
    }
    final controller = _controllers.remove(queueId);
    controller?.close();
  }

  Future<socket_io.Socket> _ensureConnected() async {
    final socket = _socket;
    if (socket != null && socket.connected) return socket;
    if (socket != null) {
      // Already constructed, just not connected yet (or reconnecting) —
      // socket.io handles retry/backoff itself once `connect()` is called.
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

    newSocket.onConnect((_) => AppLogger.info('Matchmaking socket connected', tag: 'Matchmaking'));
    newSocket.onDisconnect((_) => AppLogger.info('Matchmaking socket disconnected', tag: 'Matchmaking'));
    newSocket.onConnectError((e) => AppLogger.warning('Matchmaking socket connect error: $e', tag: 'Matchmaking'));
    newSocket.onError((e) => AppLogger.warning('Matchmaking socket error: $e', tag: 'Matchmaking'));

    _socket = newSocket;
    return newSocket;
  }

  /// Tears down the shared socket entirely — only meaningful at app
  /// shutdown or logout, not between individual queue entries (use
  /// [stopWatching] for that).
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _handlers.clear();
    _socket?.dispose();
    _socket = null;
  }
}
