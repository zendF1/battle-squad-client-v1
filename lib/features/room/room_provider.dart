import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/room_models.dart';

class RoomNotifier extends StateNotifier<RoomState?> {
  final Ref _ref;
  StreamSubscription<WsEvent>? _sub;

  RoomNotifier(this._ref) : super(null) {
    _sub = _ref.read(wsManagerProvider).eventStream.listen(_onEvent);
  }

  void _onEvent(WsEvent event) {
    if (event is RoomUpdatedEvent) {
      state = event.room;
    }
  }

  void selectCharacter(String characterId) {
    _ref.read(wsManagerProvider).send('SelectCharacter', {'character_id': characterId});
  }

  void selectItems(List<String> itemIds) {
    _ref.read(wsManagerProvider).send('SelectItems', {'items': itemIds});
  }

  void toggleReady() {
    _ref.read(wsManagerProvider).send('ToggleReady', {});
  }

  void startMatch() {
    _ref.read(wsManagerProvider).send('StartMatch', {});
  }

  void changeTeam(int teamId) {
    _ref.read(wsManagerProvider).send('ChangeTeam', {'team_id': teamId});
  }

  void leave() {
    _ref.read(wsManagerProvider).send('LeaveRoom', {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState?>(
  (ref) => RoomNotifier(ref),
);
