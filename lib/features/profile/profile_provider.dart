import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/player_models.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<PlayerProfile>> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final data = await client.get('/player/profile');
      state = AsyncValue.data(PlayerProfile.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      final client = _ref.read(apiClientProvider);
      final data = await client.put(
        '/player/profile',
        data: {'display_name': name},
      );
      state = AsyncValue.data(PlayerProfile.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<PlayerProfile>>(
  (ref) => ProfileNotifier(ref),
);

final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/player/inventory');
  final rawList =
      data['items'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
  return rawList
      .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

final matchHistoryProvider =
    FutureProvider.family<List<MatchHistoryEntry>, int>((ref, page) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get(
    '/player/match-history',
    queryParams: {'page': page, 'limit': 20},
  );
  final rawList =
      data['matches'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
  return rawList
      .map((e) => MatchHistoryEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});
