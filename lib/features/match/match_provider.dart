import 'dart:async';

import 'package:battle_squad_v1/core/providers/core_providers.dart';
import 'package:battle_squad_v1/core/ws/ws_events.dart';
import 'package:battle_squad_v1/core/ws/ws_manager.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// MatchData — UI state holder
// ---------------------------------------------------------------------------

class MatchData {
  final MatchState state;
  final ProjectileResult? lastProjectile;
  final List<ProjectileResult> projectileQueue;
  final List<DamageEntry>? lastDamages;
  final int turnTimeLeft;
  final MatchEndedData? endedData;

  /// Latest authoritative terrain from the server.
  final TerrainSnapshot? terrain;

  /// Terrain-destroying projectile results received after [terrain].
  final List<ProjectileResult> terrainOps;

  /// Highest terrain version seen (snapshot or explosion).
  final int terrainVersion;

  const MatchData({
    required this.state,
    this.lastProjectile,
    this.projectileQueue = const [],
    this.lastDamages,
    this.turnTimeLeft = 20,
    this.endedData,
    this.terrain,
    this.terrainOps = const [],
    this.terrainVersion = 0,
  });

  MatchData copyWith({
    MatchState? state,
    ProjectileResult? lastProjectile,
    bool clearLastProjectile = false,
    List<ProjectileResult>? projectileQueue,
    List<DamageEntry>? lastDamages,
    bool clearLastDamages = false,
    int? turnTimeLeft,
    MatchEndedData? endedData,
    List<ProjectileResult>? terrainOps,
    int? terrainVersion,
  }) {
    return MatchData(
      state: state ?? this.state,
      lastProjectile: clearLastProjectile
          ? null
          : (lastProjectile ?? this.lastProjectile),
      projectileQueue: projectileQueue ?? this.projectileQueue,
      lastDamages:
          clearLastDamages ? null : (lastDamages ?? this.lastDamages),
      turnTimeLeft: turnTimeLeft ?? this.turnTimeLeft,
      endedData: endedData ?? this.endedData,
      terrain: terrain,
      terrainOps: terrainOps ?? this.terrainOps,
      terrainVersion: terrainVersion ?? this.terrainVersion,
    );
  }
}

// ---------------------------------------------------------------------------
// MatchNotifier
// ---------------------------------------------------------------------------

class MatchNotifier extends StateNotifier<MatchData?> {
  final WsManager _wsManager;
  late final StreamSubscription<WsEvent> _sub;

  MatchNotifier(this._wsManager) : super(null) {
    _sub = _wsManager.eventStream.listen(_handleEvent);
  }

  void setInitialState(MatchState matchState, {TerrainSnapshot? terrain}) {
    state = _fromSnapshot(matchState, terrain, isSync: false);
  }

  /// Builds match data from a full server snapshot. A sync for the current
  /// match keeps client-side progress the snapshot does not carry (pending
  /// projectile animations, match result); a snapshot without terrain keeps
  /// the previous terrain and its pending explosions.
  MatchData _fromSnapshot(
    MatchState matchState,
    TerrainSnapshot? terrain, {
    required bool isSync,
  }) {
    final current = state;
    final sameMatch =
        current != null && current.state.matchId == matchState.matchId;
    final keep = isSync && sameMatch ? current : null;
    final prevTerrain = sameMatch ? current : null;
    return MatchData(
      state: matchState,
      turnTimeLeft: matchState.turnTimeLeft,
      lastProjectile: keep?.lastProjectile,
      projectileQueue: keep?.projectileQueue ?? const [],
      lastDamages: keep?.lastDamages,
      endedData: keep?.endedData,
      terrain: terrain ?? prevTerrain?.terrain,
      terrainOps: terrain != null
          ? const []
          : prevTerrain?.terrainOps ?? const [],
      terrainVersion: terrain?.version ?? prevTerrain?.terrainVersion ?? 0,
    );
  }

  void _handleEvent(WsEvent event) {
    switch (event) {
      case MatchStartedEvent(:final state, :final terrain):
        this.state = _fromSnapshot(state, terrain, isSync: false);

      case MatchStateSyncEvent(:final state, :final terrain):
        this.state = _fromSnapshot(state, terrain, isSync: true);

      case TurnStartedEvent(:final data):
        final current = state;
        if (current == null) return;

        // Current player's move energy resets; skill energy syncs for everyone
        final updatedPlayers = current.state.players.map(
          (id, p) => MapEntry(
            id,
            p.copyWith(
              moveEnergy: id == data.currentPlayerId ? data.moveEnergy : null,
              skillEnergy: data.skillEnergy?[id],
            ),
          ),
        );

        final newMatchState = MatchState(
          matchId: current.state.matchId,
          roomId: current.state.roomId,
          mode: current.state.mode,
          mapId: current.state.mapId,
          turnIndex: data.turnIndex,
          currentPlayerId: data.currentPlayerId,
          wind: data.wind,
          players: updatedPlayers,
          status: current.state.status,
          turnOrder: current.state.turnOrder,
          turnTimeLeft: 20,
          activeEffects: current.state.activeEffects,
        );

        state = current.copyWith(
          state: newMatchState,
          turnTimeLeft: 20,
          clearLastDamages: true,
        );

      case TurnTimerTickEvent(:final timeLeft):
        final current = state;
        if (current == null) return;
        state = current.copyWith(turnTimeLeft: timeLeft);

      case ProjectileResultEvent(:final data):
        final current = state;
        if (current == null) return;
        var terrainOps = current.terrainOps;
        var terrainVersion = current.terrainVersion;
        var missedTerrain = false;
        if (data.terrainDestroyed && data.terrainVersion > 0) {
          missedTerrain = data.terrainVersion > terrainVersion + 1;
          terrainOps = [...terrainOps, data];
          if (data.terrainVersion > terrainVersion) {
            terrainVersion = data.terrainVersion;
          }
        }
        state = current.copyWith(
          lastProjectile: data,
          projectileQueue: [...current.projectileQueue, data],
          terrainOps: terrainOps,
          terrainVersion: terrainVersion,
        );
        // A skipped version means an explosion was missed: resync terrain.
        if (missedTerrain) reconnect();

      case PlayerDamagedEvent(:final damages):
        final current = state;
        if (current == null) return;

        final updatedPlayers =
            Map<String, BattlePlayerState>.from(current.state.players);
        for (final dmg in damages) {
          if (updatedPlayers.containsKey(dmg.playerId)) {
            final p = updatedPlayers[dmg.playerId]!;
            updatedPlayers[dmg.playerId] = BattlePlayerState(
              playerId: p.playerId,
              displayName: p.displayName,
              teamId: p.teamId,
              characterId: p.characterId,
              hp: dmg.hp,
              maxHp: p.maxHp,
              defense: p.defense,
              position: p.position,
              moveEnergy: p.moveEnergy,
              items: p.items,
              statusEffects: p.statusEffects,
              isAlive: dmg.isAlive,
              isBot: p.isBot,
              skillEnergy: p.skillEnergy,
              damageDealt: p.damageDealt,
              killCount: p.killCount,
              shotsFired: p.shotsFired,
              shotsHit: p.shotsHit,
            );
          }
        }

        final newMatchState = MatchState(
          matchId: current.state.matchId,
          roomId: current.state.roomId,
          mode: current.state.mode,
          mapId: current.state.mapId,
          turnIndex: current.state.turnIndex,
          currentPlayerId: current.state.currentPlayerId,
          wind: current.state.wind,
          players: updatedPlayers,
          status: current.state.status,
          turnOrder: current.state.turnOrder,
          turnTimeLeft: current.state.turnTimeLeft,
          activeEffects: current.state.activeEffects,
        );
        state = current.copyWith(
          state: newMatchState,
          lastDamages: damages,
        );

      case PlayerMovedEvent(:final data):
        final current = state;
        if (current == null) return;

        final updatedPlayers =
            Map<String, BattlePlayerState>.from(current.state.players);
        if (updatedPlayers.containsKey(data.playerId)) {
          final p = updatedPlayers[data.playerId]!;
          updatedPlayers[data.playerId] = BattlePlayerState(
            playerId: p.playerId,
            displayName: p.displayName,
            teamId: p.teamId,
            characterId: p.characterId,
            hp: p.hp,
            maxHp: p.maxHp,
            defense: p.defense,
            position: data.position,
            moveEnergy: data.moveEnergy,
            items: p.items,
            statusEffects: p.statusEffects,
            isAlive: p.isAlive,
            isBot: p.isBot,
            skillEnergy: p.skillEnergy,
            damageDealt: p.damageDealt,
            killCount: p.killCount,
            shotsFired: p.shotsFired,
            shotsHit: p.shotsHit,
          );
        }

        final newMatchState = MatchState(
          matchId: current.state.matchId,
          roomId: current.state.roomId,
          mode: current.state.mode,
          mapId: current.state.mapId,
          turnIndex: current.state.turnIndex,
          currentPlayerId: current.state.currentPlayerId,
          wind: current.state.wind,
          players: updatedPlayers,
          status: current.state.status,
          turnOrder: current.state.turnOrder,
          turnTimeLeft: current.state.turnTimeLeft,
          activeEffects: current.state.activeEffects,
        );
        state = current.copyWith(state: newMatchState);

      case MatchEndedEvent(:final data):
        final current = state;
        if (current == null) return;
        state = current.copyWith(endedData: data);

      case SkillUsedEvent(:final playerId, :final hp, :final skillEnergy):
        final current = state;
        if (current == null) return;
        if (hp != null || skillEnergy != null) {
          final updatedPlayers =
              Map<String, BattlePlayerState>.from(current.state.players);
          final p = updatedPlayers[playerId];
          if (p != null) {
            updatedPlayers[playerId] =
                p.copyWith(hp: hp, skillEnergy: skillEnergy);
          }
          final newMatchState = MatchState(
            matchId: current.state.matchId,
            roomId: current.state.roomId,
            mode: current.state.mode,
            mapId: current.state.mapId,
            turnIndex: current.state.turnIndex,
            currentPlayerId: current.state.currentPlayerId,
            wind: current.state.wind,
            players: updatedPlayers,
            status: current.state.status,
            turnOrder: current.state.turnOrder,
            turnTimeLeft: current.state.turnTimeLeft,
            activeEffects: current.state.activeEffects,
          );
          state = current.copyWith(state: newMatchState);
        }

      case ItemUsedEvent(:final players, :final wind):
        final current = state;
        if (current == null) return;
        if (players != null || wind != null) {
          final newMatchState = MatchState(
            matchId: current.state.matchId,
            roomId: current.state.roomId,
            mode: current.state.mode,
            mapId: current.state.mapId,
            turnIndex: current.state.turnIndex,
            currentPlayerId: current.state.currentPlayerId,
            wind: wind ?? current.state.wind,
            players: players ?? current.state.players,
            status: current.state.status,
            turnOrder: current.state.turnOrder,
            turnTimeLeft: current.state.turnTimeLeft,
            activeEffects: current.state.activeEffects,
          );
          state = current.copyWith(state: newMatchState);
        }

      case WsReconnectedEvent():
        if (state != null) {
          reconnect();
        }

      default:
        // Other events (room events, disconnect, etc.) — ignore
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void shoot({
    required double angle,
    required int power,
    required String actionMode,
    String? itemId,
    double? targetX,
  }) {
    _wsManager.send('Shoot', {
      'angle': angle,
      'power': power,
      'actionMode': actionMode,
      if (itemId != null) 'itemId': itemId,
      if (targetX != null) 'targetX': targetX,
    });
  }

  void move({required String direction, double? targetX}) {
    _wsManager.send('Move', {
      'direction': direction,
      if (targetX != null) 'targetX': targetX,
    });
  }

  void useItem({required String itemId, Vector2Model? targetPosition}) {
    _wsManager.send('UseItem', {
      'itemId': itemId,
      if (targetPosition != null)
        'targetPosition': {'x': targetPosition.x, 'y': targetPosition.y},
    });
  }

  void endTurn() {
    _wsManager.send('EndTurn', {});
  }

  void clearProjectileQueue() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(projectileQueue: []);
  }

  void reconnect() {
    _wsManager.send('Reconnect', {});
  }

  void leave() {
    _wsManager.send('Leave', {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final matchProvider = StateNotifierProvider<MatchNotifier, MatchData?>((ref) {
  final wsManager = ref.watch(wsManagerProvider);
  return MatchNotifier(wsManager);
});
