import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../api/api_config.dart';
import '../auth/auth_controller.dart';
import '../auth/secure_session_store.dart';

/// The API broadcasts tenant-scoped notifications, never full message content.
class InboxRealtimeEvent {
  const InboxRealtimeEvent(this.conversationId);

  /// Null means the connection was restored and all visible data must be synced.
  final int? conversationId;
}

final inboxRealtimeProvider =
    StreamProvider.autoDispose<InboxRealtimeEvent>((ref) {
  final service = InboxRealtimeService(ref.read(sessionStoreProvider));
  ref.onDispose(service.dispose);
  unawaited(service.start());
  return service.events;
});

class InboxRealtimeService {
  InboxRealtimeService(this._session);

  final SecureSessionStore _session;
  final _events = StreamController<InboxRealtimeEvent>.broadcast();
  HubConnection? _connection;
  Timer? _retry;
  bool _disposed = false;
  bool _starting = false;
  int _retryCount = 0;

  Stream<InboxRealtimeEvent> get events => _events.stream;

  Future<void> start() async {
    if (_disposed || _starting) return;
    final token = await _session.readValidToken();
    if (_disposed || token == null) return;
    _starting = true;
    try {
      final connection = _connection ??= _buildConnection();
      if (connection.state == HubConnectionState.Disconnected) {
        await connection.start();
      }
      if (_disposed) {
        await connection.stop();
        return;
      }
      _retryCount = 0;
      _emit(null); // Catch notifications missed during connection downtime.
    } catch (_) {
      _scheduleRetry();
    } finally {
      _starting = false;
    }
  }

  HubConnection _buildConnection() {
    final url =
        '${ApiConfig.baseUrl.replaceFirst(RegExp(r"/+$"), "")}/hubs/communication';
    final connection = HubConnectionBuilder()
        .withUrl(url,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  await _session.readValidToken() ?? '',
            ))
        .withAutomaticReconnect(retryDelays: [0, 2000, 10000, 30000]).build();

    for (final name in [
      'conversation.message.changed',
      'conversation.message.status.changed',
      'conversation.updated',
    ]) {
      connection.on(name, (arguments) {
        if (_disposed || arguments == null || arguments.isEmpty) return;
        final payload = arguments.first;
        if (payload is! Map) return;
        final idValue = payload['conversationId'] ?? payload['ConversationId'];
        final id = idValue is num ? idValue.toInt() : int.tryParse('$idValue');
        if (id != null && id > 0) _emit(id);
      });
    }
    connection.onreconnected(({connectionId}) {
      if (_disposed) return;
      _retryCount = 0;
      _emit(null);
    });
    connection.onclose(({error}) {
      if (!_disposed) _scheduleRetry();
    });
    return connection;
  }

  void _emit(int? id) {
    if (!_disposed && !_events.isClosed) _events.add(InboxRealtimeEvent(id));
  }

  void _scheduleRetry() {
    if (_disposed || _retry != null) return;
    final delay = Duration(
        seconds: [1, 2, 5, 10, 30][(_retryCount < 4 ? _retryCount : 4)]);
    if (_retryCount < 4) _retryCount++;
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(start());
    });
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    final connection = _connection;
    if (connection != null) unawaited(connection.stop());
    unawaited(_events.close());
  }
}
