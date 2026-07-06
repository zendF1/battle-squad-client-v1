import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:battle_squad_v1/shared/models/room_models.dart';

// ---------------------------------------------------------------------------
// Envelope
// ---------------------------------------------------------------------------

class WsEnvelope {
  final String event;
  final Map<String, dynamic> data;

  const WsEnvelope({required this.event, required this.data});

  factory WsEnvelope.fromJson(Map<String, dynamic> json) {
    return WsEnvelope(
      event: json['event'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
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
        return RoomErrorEvent(
          code: d['code'] as String,
          message: d['message'] as String,
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
        // Accept both array and single-object formats.
        final raw = d['damages'] ?? d;
        final List<dynamic> list =
            raw is List ? raw : [raw];
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

      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}
