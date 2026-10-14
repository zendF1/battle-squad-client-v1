import 'package:flutter/foundation.dart';

import 'package:battle_squad_v1/shared/models/lobby_models.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:battle_squad_v1/shared/models/room_models.dart';

// ---------------------------------------------------------------------------
// Envelope
// ---------------------------------------------------------------------------

class WsEnvelope {
  final String event;
  final Map<String, dynamic> data;

  /// Raw data preserved when the server sends a non-Map payload (e.g. array).
  final dynamic rawData;

  const WsEnvelope({required this.event, required this.data, this.rawData});

  factory WsEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final Map<String, dynamic> data;
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is Map) {
      data = Map<String, dynamic>.from(raw);
    } else {
      data = {};
    }
    return WsEnvelope(event: json['event'] as String, data: data, rawData: raw);
  }

  Map<String, dynamic> toJson() => {'event': event, 'data': data};
}

// ---------------------------------------------------------------------------
// Sealed event hierarchy
// ---------------------------------------------------------------------------

sealed class WsEvent {}

class RoomUpdatedEvent extends WsEvent {
  final RoomState room;
  RoomUpdatedEvent(this.room);
}

class RoomErrorEvent extends WsEvent {
  final String code;
  final String message;
  RoomErrorEvent({required this.code, required this.message});
}

class MatchStartedEvent extends WsEvent {
  final MatchState state;
  MatchStartedEvent(this.state);
}

class TurnStartedEvent extends WsEvent {
  final TurnStartedData data;
  TurnStartedEvent(this.data);
}

class TurnTimerTickEvent extends WsEvent {
  final int timeLeft;
  TurnTimerTickEvent(this.timeLeft);
}

class PlayerMovedEvent extends WsEvent {
  final PlayerMovedData data;
  PlayerMovedEvent(this.data);
}

class ProjectileResultEvent extends WsEvent {
  final ProjectileResult data;
  ProjectileResultEvent(this.data);
}

class PlayerDamagedEvent extends WsEvent {
  final List<DamageEntry> damages;
  PlayerDamagedEvent(this.damages);
}

class SkillUsedEvent extends WsEvent {
  final String playerId;
  final String skillId;
  final int? hp;
  SkillUsedEvent({required this.playerId, required this.skillId, this.hp});
}

class ItemUsedEvent extends WsEvent {
  final String playerId;
  final String itemId;
  final Map<String, BattlePlayerState>? players;
  final WindState? wind;
  ItemUsedEvent({
    required this.playerId,
    required this.itemId,
    this.players,
    this.wind,
  });
}

class MatchEndedEvent extends WsEvent {
  final MatchEndedData data;
  MatchEndedEvent(this.data);
}

class MatchStateSyncEvent extends WsEvent {
  final MatchState state;
  MatchStateSyncEvent(this.state);
}

class LobbyUpdatedEvent extends WsEvent {
  final LobbyState lobby;
  LobbyUpdatedEvent(this.lobby);
}

class QueueStartedEvent extends WsEvent {
  final int? estimatedWait;
  QueueStartedEvent({this.estimatedWait});
}

class QueueCancelledEvent extends WsEvent {
  final String reason;
  QueueCancelledEvent(this.reason);
}

class MatchFoundEvent extends WsEvent {
  final String roomId;
  final String? matchId;
  MatchFoundEvent({required this.roomId, this.matchId});
}

class LobbyDisbandedEvent extends WsEvent {
  final String reason;
  LobbyDisbandedEvent(this.reason);
}

class ReturnToLobbyEvent extends WsEvent {
  final String lobbyId;
  ReturnToLobbyEvent(this.lobbyId);
}

class LobbyErrorEvent extends WsEvent {
  final String code;
  final String message;
  LobbyErrorEvent({required this.code, required this.message});
}

class WsDisconnectedEvent extends WsEvent {}

class WsReconnectedEvent extends WsEvent {}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

WsEvent? parseWsEvent(WsEnvelope envelope) {
  try {
    final d = envelope.data;
    switch (envelope.event) {
      case 'RoomUpdated':
        return RoomUpdatedEvent(RoomState.fromJson(d));

      case 'RoomError':
        // Server sends nested: {"error":{"code":"...","message":"..."}}
        final err = d['error'] as Map<String, dynamic>? ?? d;
        return RoomErrorEvent(
          code: err['code'] as String? ?? 'UNKNOWN',
          message: err['message'] as String? ?? 'Unknown error',
        );

      case 'MatchStarted':
        return MatchStartedEvent(MatchState.fromJson(d));

      case 'TurnStarted':
        return TurnStartedEvent(TurnStartedData.fromJson(d));

      case 'TurnTimerTick':
        return TurnTimerTickEvent(d['timeLeft'] as int);

      case 'PlayerMoved':
        return PlayerMovedEvent(PlayerMovedData.fromJson(d));

      case 'ProjectileResult':
        return ProjectileResultEvent(ProjectileResult.fromJson(d));

      case 'PlayerDamaged':
        // Server may send data as a top-level array or as {damages: [...]}.
        final raw = envelope.rawData;
        final List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (d.containsKey('damages')) {
          final v = d['damages'];
          list = v is List ? v : [v];
        } else {
          list = [d];
        }
        final damages =
            list.map((e) => DamageEntry.fromJson(e as Map<String, dynamic>)).toList();
        return PlayerDamagedEvent(damages);

      case 'SkillUsed':
        return SkillUsedEvent(
          playerId: d['playerId'] as String,
          skillId: d['skillId'] as String,
          hp: d['hp'] as int?,
        );

      case 'ItemUsed':
        Map<String, BattlePlayerState>? players;
        if (d['players'] != null) {
          players = (d['players'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, BattlePlayerState.fromJson(v as Map<String, dynamic>)),
          );
        }
        final wind =
            d['wind'] != null ? WindState.fromJson(d['wind'] as Map<String, dynamic>) : null;
        return ItemUsedEvent(
          playerId: d['playerId'] as String,
          itemId: d['itemId'] as String,
          players: players,
          wind: wind,
        );

      case 'MatchEnded':
        return MatchEndedEvent(MatchEndedData.fromJson(d));

      case 'MatchStateSync':
        return MatchStateSyncEvent(MatchState.fromJson(d));

      case 'LobbyUpdated':
        return LobbyUpdatedEvent(LobbyState.fromJson(d));

      case 'QueueStarted':
        return QueueStartedEvent(estimatedWait: d['estimatedWait'] as int?);

      case 'QueueCancelled':
        return QueueCancelledEvent(d['reason'] as String? ?? 'unknown');

      case 'MatchFound':
        return MatchFoundEvent(
          roomId: d['roomId'] as String,
          matchId: d['matchId'] as String?,
        );

      case 'LobbyDisbanded':
        return LobbyDisbandedEvent(d['reason'] as String? ?? 'unknown');

      case 'ReturnToLobby':
        return ReturnToLobbyEvent(d['lobbyId'] as String);

      case 'LobbyError':
        final err = d['error'] as Map<String, dynamic>? ?? d;
        return LobbyErrorEvent(
          code: err['code'] as String? ?? 'UNKNOWN',
          message: err['message'] as String? ?? 'Unknown error',
        );

      default:
        return null;
    }
  } catch (e, st) {
    debugPrint('[WS] parseWsEvent error for "${envelope.event}": $e\n$st');
    return null;
  }
}
