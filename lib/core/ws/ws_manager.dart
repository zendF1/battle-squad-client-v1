import 'dart:async';
import 'dart:convert';

import 'package:battle_squad_v1/core/ws/ws_events.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ---------------------------------------------------------------------------
// Connection state
// ---------------------------------------------------------------------------

enum WsConnectionState { disconnected, connecting, connected }

// ---------------------------------------------------------------------------
// WsManager
// ---------------------------------------------------------------------------

class WsManager {
  final String baseUrl;

  WsManager(this.baseUrl);

  // Internal state
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _token;
  int _attempts = 0;
  Timer? _reconnectTimer;

  WsConnectionState _state = WsConnectionState.disconnected;

  // Broadcast controllers
  final _eventController = StreamController<WsEvent>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();

  // Public streams
  Stream<WsEvent> get eventStream => _eventController.stream;
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void connect(String token) {
    _token = token;
    _attempts = 0;
    _doConnect();
  }

  void send(String event, Map<String, dynamic> data) {
    debugPrint('[WS] send: $event state=$_state channel=${_channel != null}');
    if (_channel == null) {
      debugPrint('[WS] WARNING: no channel, message dropped!');
      return;
    }
    final envelope = WsEnvelope(event: event, data: data);
    _channel!.sink.add(jsonEncode(envelope.toJson()));
  }

  void disconnect() {
    _token = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeChannel();
    _setState(WsConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _doConnect() {
    if (_token == null) return;

    final url = '$baseUrl/ws?token=$_token';
    debugPrint('[WS] connecting to $url');
    _setState(WsConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint('[WS] stream error: $e');
          _onDisconnected();
        },
        onDone: () {
          debugPrint('[WS] stream done (disconnected)');
          _onDisconnected();
        },
        cancelOnError: true,
      );

      final wasReconnect = _attempts > 0;
      _attempts = 0;
      _setState(WsConnectionState.connected);
      debugPrint('[WS] connected');
      if (wasReconnect) {
        _eventController.add(WsReconnectedEvent());
      }
    } catch (e) {
      debugPrint('[WS] connect error: $e');
      _onDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      debugPrint('[WS] recv: ${(raw as String).substring(0, (raw as String).length > 100 ? 100 : (raw as String).length)}');
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      final envelope = WsEnvelope.fromJson(decoded);
      final event = parseWsEvent(envelope);
      if (event != null) {
        _eventController.add(event);
      }
    } catch (e) {
      debugPrint('[WS] parse error: $e');
    }
  }

  void _onDisconnected() {
    _closeChannel();
    _setState(WsConnectionState.disconnected);
    _eventController.add(WsDisconnectedEvent());
    if (_token != null) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _attempts++;
    final delaySecs = _attempts < 5
        ? (1 << _attempts).clamp(1, 30) // 2^attempts, max 30 s
        : 30;
    _reconnectTimer = Timer(Duration(seconds: delaySecs), _doConnect);
  }

  void _closeChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _setState(WsConnectionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
