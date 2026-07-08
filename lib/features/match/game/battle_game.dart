import 'dart:ui';

import 'package:battle_squad_v1/features/match/game/cancel_zone_component.dart';
import 'package:battle_squad_v1/features/match/game/explosion_component.dart';
import 'package:battle_squad_v1/features/match/game/player_component.dart';
import 'package:battle_squad_v1/features/match/game/projectile_component.dart';
import 'package:battle_squad_v1/features/match/game/terrain_component.dart';
import 'package:battle_squad_v1/features/match/game/trajectory_component.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';


class BattleGame extends FlameGame {
  final String mapId;
  final Map<String, BattlePlayerState> initialPlayers;
  final int localTeamId;

  late TerrainComponent _terrainComponent;
  late TrajectoryComponent _trajectoryComponent;
  late CancelZoneComponent _cancelZoneComponent;
  final Map<String, PlayerComponent> playerComponents = {};

  static const double _gameWidth = 1600;
  static const double _gameHeight = 900;

  BattleGame({
    required this.mapId,
    required this.initialPlayers,
    required this.localTeamId,
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

    // Add player components (with terrain reference for client-side gravity)
    for (final entry in initialPlayers.entries) {
      final ps = entry.value;
      final comp = PlayerComponent(
        playerId: ps.playerId,
        terrainData: terrainData,
        displayName: ps.displayName,
        characterId: ps.characterId,
        teamId: ps.teamId,
        isAlly: ps.teamId == localTeamId,
        hp: ps.hp,
        maxHp: ps.maxHp,
        isAlive: ps.isAlive,
        initialPosition: Vector2(ps.position.x, ps.position.y),
      );
      playerComponents[entry.key] = comp;
      world.add(comp);
    }

    // Add trajectory preview (always present, just hidden)
    _trajectoryComponent = TrajectoryComponent();
    world.add(_trajectoryComponent);

    _cancelZoneComponent = CancelZoneComponent();
    _cancelZoneComponent.hide();
    world.add(_cancelZoneComponent);

    await super.onLoad();
  }

  /// Update a player's state from server.
  /// X, HP, isAlive are applied immediately. Y is stored for gravity anti-desync.
  void updatePlayer(
    String playerId, {
    int? hp,
    bool? isAlive,
    double? x,
    double? serverY,
  }) {
    final comp = playerComponents[playerId];
    if (comp == null) return;
    comp.updateFromState(
      newHp: hp ?? comp.hp,
      alive: isAlive ?? comp.isAlive,
      newX: x,
      serverY: serverY,
    );
  }

  /// Show trajectory preview for aiming.
  void showTrajectory({
    required String playerId,
    required double angleDeg,
    required double power,
    required int windDirection,
    required int windPower,
  }) {
    final comp = playerComponents[playerId];
    if (comp == null) return;
    _trajectoryComponent.update2(
      origin: comp.position.clone(),
      angleDeg: angleDeg,
      power: power,
      windDirection: windDirection,
      windPower: windPower,
    );
  }

  /// Hide trajectory preview.
  void hideTrajectory() {
    _trajectoryComponent.hide();
  }

  /// Animate a projectile result: fly path → explosion → terrain destruction.
  /// Players fall automatically via client-side gravity when terrain is destroyed.
  void animateProjectile(ProjectileResult result) {
    hideTrajectory();
    if (result.path.isEmpty) {
      _handleExplosion(result);
      return;
    }

    final projectile = ProjectileComponent(
      path: result.path,
      onComplete: () => _handleExplosion(result),
    );
    world.add(projectile);
  }

  void _handleExplosion(ProjectileResult result) {
    // Teleport or other no-damage projectiles: skip explosion
    if (result.explosionRadius <= 0) return;

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
    // Terrain mask updated → PlayerComponent.update() detects lost support → falls with gravity

    final explosion = ExplosionComponent(
      center: center,
      radius: result.explosionRadius.clamp(10, 120),
      onComplete: () {},
    );
    world.add(explosion);
  }

  void showCancelZone(String playerId) {
    final comp = playerComponents[playerId];
    if (comp == null) return;
    _cancelZoneComponent.show(comp.position.clone());
  }

  void hideCancelZone() {
    _cancelZoneComponent.hide();
  }

  bool isInCancelZone(Vector2 worldPoint) {
    return _cancelZoneComponent.containsPoint(worldPoint);
  }

  void setCancelZoneHighlight(bool highlighted) {
    _cancelZoneComponent.isHighlighted = highlighted;
  }

  Vector2 screenToWorld(Offset screenPos) {
    return camera.viewfinder.globalToLocal(Vector2(screenPos.dx, screenPos.dy));
  }

  /// Move the camera viewfinder to follow a target position.
  void followTarget(Vector2 target) {
    camera.viewfinder.position = target;
  }
}
