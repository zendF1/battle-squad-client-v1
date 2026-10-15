import 'package:battle_squad_v1/features/match/game/player_component.dart';
import 'package:battle_squad_v1/features/match/game/terrain_component.dart';
import 'package:battle_squad_v1/features/match/game/trajectory_component.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'terrain_test.dart' show encodeMaskRle;

/// 100x200 terrain with a platform at y=50..59 and a floor from y=150.
TerrainData twoLevelTerrain() {
  const w = 100, h = 200;
  final solid = List<int>.generate(w * h, (i) {
    final y = i ~/ w;
    return (y >= 50 && y < 60) || y >= 150 ? 1 : 0;
  });
  return TerrainData.fromSnapshot(
    TerrainSnapshot(
      width: w,
      height: h,
      version: 0,
      solid: encodeMaskRle(solid),
      destructible: encodeMaskRle(solid),
    ),
    mapId: 'm',
  );
}

PlayerComponent playerAt(TerrainData terrain, double x, double y) =>
    PlayerComponent(
      playerId: 'p',
      terrainData: terrain,
      displayName: 'p',
      characterId: 'c',
      teamId: 1,
      isAlly: true,
      hp: 100,
      maxHp: 100,
      isAlive: true,
      initialPosition: Vector2(x, y),
    );

void main() {
  test(
    'snapToServer moves a player standing on a platform to a lower floor',
    () {
      final terrain = twoLevelTerrain();
      final player = playerAt(terrain, 50, 50);

      // Regular update: the platform still supports the player, Y stays put.
      player.updateFromState(newHp: 100, alive: true, newX: 50, serverY: 150);
      player.update(0.1);
      expect(player.position.y, 50);

      player.snapToServer(50, 150);
      player.update(0.1);
      expect(player.position.y, 150);
    },
  );

  test('trajectory preview runs to the edge of a wide world', () {
    final trajectory = TrajectoryComponent(worldWidth: 3200, worldHeight: 900)
      ..update2(
        origin: Vector2(2000, 400),
        angleDeg: 10,
        power: 60,
        windDirection: 0,
        windPower: 0,
      );
    final path = trajectory.computePath();
    expect(path.length, greaterThan(2));
    expect(path.last.x, greaterThan(2400));
  });
}
