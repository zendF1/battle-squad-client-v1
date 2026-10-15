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
import 'package:flutter/foundation.dart';

class BattleGame extends FlameGame {
  final String mapId;
  final Map<String, BattlePlayerState> initialPlayers;
  final int localTeamId;

  /// Latest server terrain and the explosions received after it was taken.
  TerrainSnapshot _terrain;
  List<ProjectileResult> _terrainOps;
  TerrainData? _terrainData;

  /// Projectiles queued or flying whose explosions have not been applied yet.
  /// A server snapshot already contains their craters, so snapshots and
  /// authoritative positions wait until the last one explodes.
  int _projectilesInFlight = 0;
  bool _snapshotPending = false;

  /// Explosions that landed while a snapshot was waiting; replayed on top of
  /// it (those already in the snapshot are skipped by version).
  final List<ProjectileResult> _landedWhilePending = [];

  /// Authoritative positions waiting for the players to exist or for
  /// in-flight projectiles to land. Later [updatePlayer] calls overwrite
  /// entries so the snap uses the newest server position.
  Map<String, Vector2>? _pendingPlayerSnap;

  late TerrainComponent _terrainComponent;
  late TrajectoryComponent _trajectoryComponent;
  late CancelZoneComponent _cancelZoneComponent;
  final Map<String, PlayerComponent> playerComponents = {};

  BattleGame({
    required this.mapId,
    required TerrainSnapshot terrain,
    List<ProjectileResult> terrainOps = const [],
    required this.initialPlayers,
    required this.localTeamId,
  }) : _terrain = terrain,
       _terrainOps = terrainOps;

  double get worldWidth => _terrain.width.toDouble();
  double get worldHeight => _terrain.height.toDouble();

  @override
  Future<void> onLoad() async {
    // Fit the camera to the map's world size
    camera.viewfinder.visibleGameSize = Vector2(worldWidth, worldHeight);
    camera.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    // Add terrain from the server snapshot, then replay explosions since it
    final terrainData = TerrainData.fromSnapshot(_terrain, mapId: mapId);
    _terrainData = terrainData;
    _terrainOps.forEach(_applyTerrainOp);
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

    final pendingSnap = _pendingPlayerSnap;
    if (pendingSnap != null) {
      _pendingPlayerSnap = null;
      _snapPositions(pendingSnap);
    }

    // Add trajectory preview (always present, just hidden)
    _trajectoryComponent = TrajectoryComponent(
      worldWidth: worldWidth,
      worldHeight: worldHeight,
    );
    world.add(_trajectoryComponent);

    _cancelZoneComponent = CancelZoneComponent();
    _cancelZoneComponent.hide();
    world.add(_cancelZoneComponent);

    await super.onLoad();
  }

  /// Replace terrain with a newer server snapshot (e.g. after reconnect) and
  /// replay the explosions received since it.
  void applyTerrainSnapshot(
    TerrainSnapshot snapshot,
    List<ProjectileResult> terrainOps,
  ) {
    _terrain = snapshot;
    _terrainOps = terrainOps;
    final terrainData = _terrainData;
    if (terrainData == null) return; // onLoad builds from the latest snapshot
    if (_projectilesInFlight > 0) {
      _snapshotPending = true; // applied once in-flight projectiles land
      return;
    }
    terrainData.loadSnapshot(snapshot);
    terrainOps.forEach(_applyTerrainOp);
  }

  /// Place players at their authoritative server positions immediately
  /// (full state sync). Regular updates keep going through [updatePlayer].
  void snapPlayers(Map<String, BattlePlayerState> players) {
    _snapPositions({
      for (final entry in players.entries)
        entry.key: Vector2(entry.value.position.x, entry.value.position.y),
    });
  }

  void _snapPositions(Map<String, Vector2> positions) {
    if (playerComponents.isEmpty || _projectilesInFlight > 0) {
      _pendingPlayerSnap = positions; // applied after onLoad / when shots land
      return;
    }
    for (final entry in positions.entries) {
      playerComponents[entry.key]?.snapToServer(entry.value.x, entry.value.y);
    }
  }

  void _applyTerrainOp(ProjectileResult result) {
    final ep = result.explosionPoint;
    if (!result.terrainDestroyed || ep == null) return;
    _terrainData?.destroyCircle(
      ep.x,
      ep.y,
      result.explosionRadius,
      version: result.terrainVersion,
    );
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
    // Keep a deferred snap in step with newer server positions, so it does
    // not pull the player back when it is finally applied.
    final pending = _pendingPlayerSnap?[playerId];
    if (pending != null) {
      if (x != null) pending.x = x;
      if (serverY != null) pending.y = serverY;
    }

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

  /// Animate projectile results: fly path → explosion → terrain destruction.
  /// Multiple projectiles (e.g. triple_shot) are staggered by 100ms each.
  /// Players fall automatically via client-side gravity when terrain is destroyed.
  void animateProjectiles(List<ProjectileResult> results) {
    if (results.isEmpty) return;
    hideTrajectory();
    _projectilesInFlight += results.length;
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      if (i == 0) {
        _launchProjectile(result);
      } else {
        Future.delayed(
          Duration(milliseconds: 100 * i),
          () => _launchProjectile(result),
        );
      }
    }
  }

  void _launchProjectile(ProjectileResult result) {
    if (result.path.isEmpty) {
      _onProjectileDone(result);
      return;
    }
    world.add(
      ProjectileComponent(
        path: result.path,
        onComplete: () => _onProjectileDone(result),
      ),
    );
  }

  void _onProjectileDone(ProjectileResult result) {
    _handleExplosion(result);
    if (_snapshotPending) _landedWhilePending.add(result);
    _projectilesInFlight--;
    if (_projectilesInFlight == 0) _applyDeferredSync();
  }

  /// Apply the snapshot and positions that arrived while projectiles flew.
  void _applyDeferredSync() {
    if (_snapshotPending) {
      _snapshotPending = false;
      _terrainData?.loadSnapshot(_terrain);
      _terrainOps.forEach(_applyTerrainOp);
      _landedWhilePending.forEach(_applyTerrainOp);
      _landedWhilePending.clear();
    }
    final positions = _pendingPlayerSnap;
    if (positions != null) {
      _pendingPlayerSnap = null;
      _snapPositions(positions);
    }
  }

  @visibleForTesting
  TerrainData? get terrainData => _terrainData;

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
            : Vector2(worldWidth / 2, worldHeight / 2);

    _applyTerrainOp(result);
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
