import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/lobby_models.dart';

enum RankedLobbyStatus { idle, preparing, inQueue, inMatch, disbanded, error }

class RankedLobbyData {
  final RankedLobbyStatus status;
  final LobbyState? lobby;
  final String? errorMessage;

  const RankedLobbyData({
    this.status = RankedLobbyStatus.idle,
    this.lobby,
    this.errorMessage,
  });

  RankedLobbyData copyWith({
    RankedLobbyStatus? status,
    LobbyState? lobby,
    bool clearLobby = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RankedLobbyData(
      status: status ?? this.status,
      lobby: clearLobby ? null : (lobby ?? this.lobby),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isHost {
    if (lobby == null) return false;
    return true; // Host check done against playerId in the screen
  }
}

class RankedLobbyNotifier extends StateNotifier<RankedLobbyData> {
  final Ref _ref;
  StreamSubscription<WsEvent>? _sub;

  RankedLobbyNotifier(this._ref) : super(const RankedLobbyData()) {
    _sub = _ref.read(wsManagerProvider).eventStream.listen(_onEvent);
  }

  void _onEvent(WsEvent event) {
    switch (event) {
      case LobbyUpdatedEvent(:final lobby):
        final uiStatus = switch (lobby.status) {
          'in_queue' => RankedLobbyStatus.inQueue,
          'in_match' => RankedLobbyStatus.inMatch,
          _ => RankedLobbyStatus.preparing,
        };
        state = state.copyWith(
          status: uiStatus,
          lobby: lobby,
          clearError: true,
        );

      case QueueStartedEvent():
        state = state.copyWith(status: RankedLobbyStatus.inQueue, clearError: true);

      case QueueCancelledEvent():
        state = state.copyWith(status: RankedLobbyStatus.preparing, clearError: true);

      case MatchFoundEvent():
        state = state.copyWith(status: RankedLobbyStatus.inMatch);

      case LobbyDisbandedEvent(:final reason):
        state = RankedLobbyData(
          status: RankedLobbyStatus.disbanded,
          errorMessage: 'Lobby disbanded: $reason',
        );

      case ReturnToLobbyEvent():
        // After match ends, lobby state will come via LobbyUpdated
        state = state.copyWith(status: RankedLobbyStatus.preparing, clearError: true);

      case LobbyErrorEvent(:final message):
        state = state.copyWith(errorMessage: message);

      default:
        break;
    }
  }

  void createLobby() {
    _ref.read(wsManagerProvider).send('CreateLobby', {});
  }

  void joinLobby(String lobbyId) {
    _ref.read(wsManagerProvider).send('JoinLobby', {'lobbyId': lobbyId});
  }

  void leaveLobby() {
    _ref.read(wsManagerProvider).send('LeaveLobby', {});
    state = const RankedLobbyData();
  }

  void updateLoadout({String? characterId, List<String>? items}) {
    final data = <String, dynamic>{};
    if (characterId != null) data['characterId'] = characterId;
    if (items != null) data['items'] = items;
    _ref.read(wsManagerProvider).send('UpdateLoadout', data);
  }

  void startQueue() {
    _ref.read(wsManagerProvider).send('StartQueue', {});
  }

  void cancelQueue() {
    _ref.read(wsManagerProvider).send('CancelQueue', {});
  }

  void reset() {
    state = const RankedLobbyData();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final rankedLobbyProvider =
    StateNotifierProvider<RankedLobbyNotifier, RankedLobbyData>(
  (ref) => RankedLobbyNotifier(ref),
);
