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
  final List<DamageEntry>? lastDamages;
  final int turnTimeLeft;
  final MatchEndedData? endedData;

  const MatchData({
    required this.state,
    this.lastProjectile,
    this.lastDamages,
    this.turnTimeLeft = 20,
    this.endedData,
  });

  MatchData copyWith({
    MatchState? state,
    ProjectileResult? lastProjectile,
    bool clearLastProjectile = false,
    List<DamageEntry>? lastDamages,
    bool clearLastDamages = false,
    int? turnTimeLeft,
    MatchEndedData? endedData,
  }) {
    return MatchData(
      state: state ?? this.state,
      lastProjectile: clearLastProjectile
          ? null
          : (lastProjectile ?? this.lastProjectile),
      lastDamages:
          clearLastDamages ? null : (lastDamages ?? this.lastDamages),
      turnTimeLeft: turnTimeLeft ?? this.turnTimeLeft,
      endedData: endedData ?? this.endedData,
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

  void _handleEvent(WsEvent event) {
    switch (event) {
      case MatchStartedEvent(:final state):
        this.state = MatchData(state: state, turnTimeLeft: state.turnTimeLeft);

      case MatchStateSyncEvent(:final state):
        this.state = MatchData(state: state, turnTimeLeft: state.turnTimeLeft);

      case TurnStartedEvent(:final data):
        final current = state;
        if (current == null) return;

        // Rebuild players map with updated moveEnergy for current player
        final updatedPlayers =
            Map<String, BattlePlayerState>.from(current.state.players);
        if (updatedPlayers.containsKey(data.currentPlayerId)) {
          final p = updatedPlayers[data.currentPlayerId]!;
          updatedPlayers[data.currentPlayerId] = BattlePlayerState(
            playerId: p.playerId,
            displayName: p.displayName,
            teamId: p.teamId,
            characterId: p.characterId,
            hp: p.hp,
            maxHp: p.maxHp,
            defense: p.defense,
            position: p.position,
            moveEnergy: data.moveEnergy,
            items: p.items,
            statusEffects: p.statusEffects,
            isAlive: p.isAlive,
            isBot: p.isBot,
            skillCooldown: p.skillCooldown,
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
          clearLastProjectile: true,
          clearLastDamages: true,
        );

      case TurnTimerTickEvent(:final timeLeft):
        final current = state;
        if (current == null) return;
        state = current.copyWith(turnTimeLeft: timeLeft);

      case ProjectileResultEvent(:final data):
        final current = state;
        if (current == null) return;
        state = current.copyWith(lastProjectile: data);

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
              skillCooldown: p.skillCooldown,
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
            skillCooldown: p.skillCooldown,
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

      case SkillUsedEvent(:final playerId, :final hp):
        final current = state;
        if (current == null) return;
        if (hp != null) {
          final updatedPlayers =
              Map<String, BattlePlayerState>.from(current.state.players);
          if (updatedPlayers.containsKey(playerId)) {
            final p = updatedPlayers[playerId]!;
            updatedPlayers[playerId] = BattlePlayerState(
              playerId: p.playerId,
              displayName: p.displayName,
              teamId: p.teamId,
              characterId: p.characterId,
              hp: hp,
              maxHp: p.maxHp,
              defense: p.defense,
              position: p.position,
              moveEnergy: p.moveEnergy,
              items: p.items,
              statusEffects: p.statusEffects,
              isAlive: p.isAlive,
              isBot: p.isBot,
              skillCooldown: p.skillCooldown,
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
      if (targetPosition != null) 'targetX': targetPosition.x,
      if (targetPosition != null) 'targetY': targetPosition.y,
    });
  }

  void endTurn() {
    _wsManager.send('EndTurn', {});
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
