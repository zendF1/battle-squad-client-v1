import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/character_progression_models.dart';

final playerCharactersProvider =
    FutureProvider<List<PlayerCharacter>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/player/characters');
  final rawList = data['characters'] as List<dynamic>? ?? [];
  return rawList
      .map((e) => PlayerCharacter.fromJson(e as Map<String, dynamic>))
      .toList();
});

class CharacterProgressionService {
  final Ref _ref;

  CharacterProgressionService(this._ref);

  Future<void> allocateStats({
    required String characterId,
    int hp = 0,
    int damage = 0,
    int mobility = 0,
    int defense = 0,
    int skillPower = 0,
    int terrainDamage = 0,
  }) async {
    final client = _ref.read(apiClientProvider);
    await client.post('/player/character/allocate-stats', data: {
      'characterId': characterId,
      'hp': hp,
      'damage': damage,
      'mobility': mobility,
      'defense': defense,
      'skillPower': skillPower,
      'terrainDamage': terrainDamage,
    });
    _ref.invalidate(playerCharactersProvider);
  }

  Future<void> resetStats({required String characterId}) async {
    final client = _ref.read(apiClientProvider);
    await client.post('/player/character/reset-stats', data: {
      'characterId': characterId,
    });
    _ref.invalidate(playerCharactersProvider);
  }
}

final characterProgressionServiceProvider =
    Provider<CharacterProgressionService>((ref) {
  return CharacterProgressionService(ref);
});
