import 'package:battle_squad_v1/features/match/game/explosion_component.dart';
import 'package:battle_squad_v1/features/match/game/player_component.dart';
import 'package:battle_squad_v1/features/match/game/projectile_component.dart';
import 'package:battle_squad_v1/features/match/game/terrain_component.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BattleGame extends FlameGame {
  final String mapId;
  final Map<String, BattlePlayerState> initialPlayers;

  late TerrainComponent _terrainComponent;
  final Map<String, PlayerComponent> playerComponents = {};

  static const double _gameWidth = 1600;
  static const double _gameHeight = 900;

  BattleGame({
    required this.mapId,
    required this.initialPlayers,
  });

  @override
  Future<void> onLoad() async {
    // Set up camera for fixed 1600x900 world
    camera.viewfinder.visibleGameSize = Vector2(_gameWidth, _gameHeight);
    camera.viewfinder.position = Vector2(_gameWidth / 2, _gameHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    // Add terrain
    final terrainData = TerrainData(
      width: _gameWidth.toInt(),
      height: _gameHeight.toInt(),
      mapId: mapId,
    );
    _terrainComponent = TerrainComponent(terrainData);
    world.add(_terrainComponent);

    // Add player components
    for (final entry in initialPlayers.entries) {
      final ps = entry.value;
      final comp = PlayerComponent(
        playerId: ps.playerId,
        displayName: ps.displayName,
        characterId: ps.characterId,
        teamId: ps.teamId,
        hp: ps.hp,
        maxHp: ps.maxHp,
        isAlive: ps.isAlive,
        initialPosition: Vector2(ps.position.x, ps.position.y),
      );
      playerComponents[entry.key] = comp;
      world.add(comp);
    }

    await super.onLoad();
  }

  /// Update a player's state visually.
  void updatePlayer(
    String playerId, {
    int? hp,
    bool? isAlive,
    Vector2? position,
  }) {
    final comp = playerComponents[playerId];
    if (comp == null) return;
    comp.updateFromState(
      newHp: hp ?? comp.hp,
      alive: isAlive ?? comp.isAlive,
      newPos: position,
    );
  }

  /// Animate a projectile result: fly path → explosion → terrain destruction.
  void animateProjectile(ProjectileResult result, VoidCallback onDone) {
    if (result.path.isEmpty) {
      _handleExplosion(result, onDone);
      return;
    }

    final projectile = ProjectileComponent(
      path: result.path,
      onComplete: () => _handleExplosion(result, onDone),
    );
    world.add(projectile);
  }

  void _handleExplosion(ProjectileResult result, VoidCallback onDone) {
    final ep = result.explosionPoint;
    final center = ep != null
        ? Vector2(ep.x, ep.y)
        : result.path.isNotEmpty
            ? Vector2(
                result.path.last.position.x,
                result.path.last.position.y,
              )
            : Vector2(_gameWidth / 2, _gameHeight / 2);

    if (result.terrainDestroyed) {
      _terrainComponent.onTerrainDestroyed(
        center.x,
        center.y,
        result.explosionRadius,
      );
    }

    final explosion = ExplosionComponent(
      center: center,
      radius: result.explosionRadius.clamp(10, 120),
      onComplete: onDone,
    );
    world.add(explosion);
  }

  /// Move the camera viewfinder to follow a target position.
  void followTarget(Vector2 target) {
    camera.viewfinder.position = target;
  }
}
