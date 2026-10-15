import 'package:battle_squad_v1/features/match/game/battle_game.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'terrain_test.dart' show encodeMaskRle;

const w = 200, h = 100;

/// Solid from y >= 50.
TerrainSnapshot flat({int version = 0, List<int>? holeAt}) {
  final solid = List<int>.generate(w * h, (i) {
    final x = i % w, y = i ~/ w;
    if (holeAt != null &&
        (x - holeAt[0]).abs() <= 5 &&
        (y - holeAt[1]).abs() <= 5) {
      return 0;
    }
    return y >= 50 ? 1 : 0;
  });
  return TerrainSnapshot(
    width: w,
    height: h,
    version: version,
    solid: encodeMaskRle(solid),
    destructible: encodeMaskRle(
      List<int>.generate(w * h, (i) => i ~/ w >= 50 ? 1 : 0),
    ),
  );
}

ProjectileResult shot(String id, {int version = 1, double x = 100}) =>
    ProjectileResult(
  projectileId: id,
  ownerPlayerId: 'p1',
  path: [
    ProjectileStep.fromJson({
      'position': {'x': 0.0, 'y': 0.0},
      'velocity': {'x': 0.0, 'y': 0.0},
      'time': 0.0,
    }),
    ProjectileStep.fromJson({
      'position': {'x': x, 'y': 60.0},
      'velocity': {'x': 0.0, 'y': 0.0},
      'time': 1.0,
    }),
  ],
  explosionPoint: Vector2Model(x: x, y: 60),
  explosionRadius: 5,
  terrainDestroyed: true,
  terrainVersion: version,
);

BattlePlayerState player(String id, double x, double y) => BattlePlayerState(
      playerId: id,
      displayName: id,
      teamId: 1,
      characterId: 'c',
      hp: 100,
      maxHp: 100,
      defense: 0,
      position: Vector2Model(x: x, y: y),
      moveEnergy: 100,
      items: const [],
      statusEffects: const [],
      isAlive: true,
      isBot: false,
      skillEnergy: 0,
      damageDealt: 0,
      killCount: 0,
      shotsFired: 0,
      shotsHit: 0,
    );

Future<BattleGame> loadedGame({
  List<ProjectileResult> ops = const [],
  Map<String, BattlePlayerState> players = const {},
}) async {
  final game = BattleGame(
    mapId: 'm',
    terrain: flat(),
    terrainOps: ops,
    initialPlayers: players,
    localTeamId: 1,
  );
  // Same steps flame_test uses to run a game without a GameWidget.
  game.onGameResize(Vector2(800, 400));
  await game.onLoad();
  // ignore: invalid_use_of_internal_member
  game.mount();
  game.update(0);
  return game;
}

void runFor(BattleGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 0.05) {
    game.update(0.05);
  }
}

void main() {
  test(
    'snapshot arriving mid-flight waits for the projectile to land',
    () async {
      final game = await loadedGame();
      final s = shot('a');
      game.animateProjectiles([s]);
      game.update(0); // mount the projectile

      // Server snapshot already contains the crater of the flying shot.
      game.applyTerrainSnapshot(flat(version: 1, holeAt: [100, 60]), const []);
      expect(
        game.terrainData!.isSolid(100, 60),
        true,
        reason: 'crater must not appear before the shot lands',
      );

      runFor(game, 2);
      expect(game.terrainData!.isSolid(100, 60), false);
    },
  );

  test('newer explosions landing during the wait survive the snapshot',
      () async {
    final game = await loadedGame();
    game.animateProjectiles([shot('a', version: 1)]);
    game.update(0);
    game.applyTerrainSnapshot(flat(version: 1, holeAt: [100, 60]), const []);

    // Shot b (version 2) is newer than the snapshot and lands before it applies.
    game.animateProjectiles([shot('b', version: 2, x: 30)]);
    runFor(game, 2);

    expect(game.terrainData!.isSolid(100, 60), false, reason: 'from snapshot');
    expect(game.terrainData!.isSolid(30, 60), false, reason: 'shot b crater');
  });

  test('a move after a deferred position snapshot is not rolled back',
      () async {
    final game = await loadedGame(players: {'p': player('p', 20, 50)});
    game.animateProjectiles([shot('a', version: 1)]);
    game.update(0);

    // 1. Snapshot during flight: player at X=100 (deferred).
    game.snapPlayers({'p': player('p', 100, 50)});
    // 2. PlayerMoved: X=150, applied right away.
    game.updatePlayer('p', x: 150, serverY: 50);
    expect(game.playerComponents['p']!.position.x, 150);

    // 3. Shot lands: the deferred snap must use the newer position.
    runFor(game, 2);
    expect(game.playerComponents['p']!.position.x, 150);
    expect(game.playerComponents['p']!.position.y, 50);
  });

  test('snapshot with nothing in flight applies immediately', () async {
    final game = await loadedGame();
    game.applyTerrainSnapshot(flat(version: 1, holeAt: [100, 60]), const []);
    expect(game.terrainData!.isSolid(100, 60), false);
  });

  test('ops passed to a new game apply on load', () async {
    final game = await loadedGame(ops: [shot('old')]);
    expect(game.terrainData!.isSolid(100, 60), false);
  });
}
