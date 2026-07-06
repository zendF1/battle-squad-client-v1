import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/room_models.dart';

class LobbyNotifier extends StateNotifier<AsyncValue<List<RoomListItem>>> {
  final Ref _ref;

  LobbyNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final data = await client.get('/rooms');
      final rawList = data['rooms'] as List<dynamic>? ?? (data['data'] as List<dynamic>? ?? []);
      final rooms = rawList
          .map((e) => RoomListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final lobbyProvider =
    StateNotifierProvider<LobbyNotifier, AsyncValue<List<RoomListItem>>>(
  (ref) => LobbyNotifier(ref),
);
