// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vector2Model _$Vector2ModelFromJson(Map<String, dynamic> json) => Vector2Model(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
);

Map<String, dynamic> _$Vector2ModelToJson(Vector2Model instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

WindState _$WindStateFromJson(Map<String, dynamic> json) => WindState(
  direction: (json['direction'] as num).toInt(),
  power: (json['power'] as num).toInt(),
);

Map<String, dynamic> _$WindStateToJson(WindState instance) => <String, dynamic>{
  'direction': instance.direction,
  'power': instance.power,
};

StatusEffect _$StatusEffectFromJson(Map<String, dynamic> json) => StatusEffect(
  effectId: json['effectId'] as String,
  targetPlayerId: json['targetPlayerId'] as String,
  durationTurn: (json['durationTurn'] as num).toInt(),
  value: (json['value'] as num).toDouble(),
  sourcePlayerId: json['sourcePlayerId'] as String,
);

Map<String, dynamic> _$StatusEffectToJson(StatusEffect instance) =>
    <String, dynamic>{
      'effectId': instance.effectId,
      'targetPlayerId': instance.targetPlayerId,
      'durationTurn': instance.durationTurn,
      'value': instance.value,
      'sourcePlayerId': instance.sourcePlayerId,
    };

BattlePlayerState _$BattlePlayerStateFromJson(Map<String, dynamic> json) =>
    BattlePlayerState(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      teamId: (json['teamId'] as num).toInt(),
      characterId: json['characterId'] as String,
      hp: (json['hp'] as num).toInt(),
      maxHp: (json['maxHp'] as num).toInt(),
      defense: (json['defense'] as num).toInt(),
      position: Vector2Model.fromJson(json['position'] as Map<String, dynamic>),
      moveEnergy: (json['moveEnergy'] as num).toInt(),
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      statusEffects:
          (json['statusEffects'] as List<dynamic>?)
              ?.map((e) => StatusEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isAlive: json['isAlive'] as bool,
      isBot: json['isBot'] as bool,
      skillCooldown: (json['skillCooldown'] as num).toInt(),
      damageDealt: (json['damageDealt'] as num).toInt(),
      killCount: (json['killCount'] as num).toInt(),
      shotsFired: (json['shotsFired'] as num).toInt(),
      shotsHit: (json['shotsHit'] as num).toInt(),
    );

Map<String, dynamic> _$BattlePlayerStateToJson(BattlePlayerState instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'displayName': instance.displayName,
      'teamId': instance.teamId,
      'characterId': instance.characterId,
      'hp': instance.hp,
      'maxHp': instance.maxHp,
      'defense': instance.defense,
      'position': instance.position,
      'moveEnergy': instance.moveEnergy,
      'items': instance.items,
      'statusEffects': instance.statusEffects,
      'isAlive': instance.isAlive,
      'isBot': instance.isBot,
      'skillCooldown': instance.skillCooldown,
      'damageDealt': instance.damageDealt,
      'killCount': instance.killCount,
      'shotsFired': instance.shotsFired,
      'shotsHit': instance.shotsHit,
    };

ProjectileStep _$ProjectileStepFromJson(Map<String, dynamic> json) =>
    ProjectileStep(
      position: Vector2Model.fromJson(json['position'] as Map<String, dynamic>),
      velocity: Vector2Model.fromJson(json['velocity'] as Map<String, dynamic>),
      time: (json['time'] as num).toDouble(),
    );

Map<String, dynamic> _$ProjectileStepToJson(ProjectileStep instance) =>
    <String, dynamic>{
      'position': instance.position,
      'velocity': instance.velocity,
      'time': instance.time,
    };

ProjectileResult _$ProjectileResultFromJson(Map<String, dynamic> json) =>
    ProjectileResult(
      projectileId: json['projectileId'] as String,
      ownerPlayerId: json['ownerPlayerId'] as String,
      skillId: json['skillId'] as String?,
      path: (json['path'] as List<dynamic>)
          .map((e) => ProjectileStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      hitPlayerId: json['hitPlayerId'] as String?,
      explosionPoint: json['explosionPoint'] == null
          ? null
          : Vector2Model.fromJson(
              json['explosionPoint'] as Map<String, dynamic>,
            ),
      explosionRadius: (json['explosionRadius'] as num).toDouble(),
      terrainDestroyed: json['terrainDestroyed'] as bool,
    );

Map<String, dynamic> _$ProjectileResultToJson(ProjectileResult instance) =>
    <String, dynamic>{
      'projectileId': instance.projectileId,
      'ownerPlayerId': instance.ownerPlayerId,
      'skillId': instance.skillId,
      'path': instance.path,
      'hitPlayerId': instance.hitPlayerId,
      'explosionPoint': instance.explosionPoint,
      'explosionRadius': instance.explosionRadius,
      'terrainDestroyed': instance.terrainDestroyed,
    };

DamageEntry _$DamageEntryFromJson(Map<String, dynamic> json) => DamageEntry(
  playerId: json['playerId'] as String,
  damage: (json['damage'] as num).toInt(),
  hp: (json['hp'] as num).toInt(),
  isAlive: json['isAlive'] as bool,
  type: json['type'] as String?,
);

Map<String, dynamic> _$DamageEntryToJson(DamageEntry instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'damage': instance.damage,
      'hp': instance.hp,
      'isAlive': instance.isAlive,
      'type': instance.type,
    };

MatchState _$MatchStateFromJson(Map<String, dynamic> json) => MatchState(
  matchId: json['matchId'] as String,
  roomId: json['roomId'] as String,
  mode: json['mode'] as String,
  mapId: json['mapId'] as String,
  turnIndex: (json['turnIndex'] as num).toInt(),
  currentPlayerId: json['currentPlayerId'] as String,
  wind: WindState.fromJson(json['wind'] as Map<String, dynamic>),
  players: (json['players'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, BattlePlayerState.fromJson(e as Map<String, dynamic>)),
  ),
  status: json['status'] as String,
  turnOrder: (json['turnOrder'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  turnTimeLeft: (json['turnTimeLeft'] as num).toInt(),
  activeEffects: (json['activeEffects'] as List<dynamic>)
      .map((e) => StatusEffect.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MatchStateToJson(MatchState instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'roomId': instance.roomId,
      'mode': instance.mode,
      'mapId': instance.mapId,
      'turnIndex': instance.turnIndex,
      'currentPlayerId': instance.currentPlayerId,
      'wind': instance.wind,
      'players': instance.players,
      'status': instance.status,
      'turnOrder': instance.turnOrder,
      'turnTimeLeft': instance.turnTimeLeft,
      'activeEffects': instance.activeEffects,
    };

MatchReward _$MatchRewardFromJson(Map<String, dynamic> json) => MatchReward(
  exp: (json['exp'] as num).toInt(),
  coins: (json['coins'] as num).toInt(),
  gemReward: (json['gemReward'] as num?)?.toInt(),
);

Map<String, dynamic> _$MatchRewardToJson(MatchReward instance) =>
    <String, dynamic>{
      'exp': instance.exp,
      'coins': instance.coins,
      'gemReward': instance.gemReward,
    };

MatchEndedData _$MatchEndedDataFromJson(Map<String, dynamic> json) =>
    MatchEndedData(
      winningTeam: (json['winningTeam'] as num).toInt(),
      rewards: (json['rewards'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, MatchReward.fromJson(e as Map<String, dynamic>)),
      ),
      result: json['result'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$MatchEndedDataToJson(MatchEndedData instance) =>
    <String, dynamic>{
      'winningTeam': instance.winningTeam,
      'rewards': instance.rewards,
      'result': instance.result,
      'message': instance.message,
    };

TurnStartedData _$TurnStartedDataFromJson(Map<String, dynamic> json) =>
    TurnStartedData(
      turnIndex: (json['turnIndex'] as num).toInt(),
      currentPlayerId: json['currentPlayerId'] as String,
      wind: WindState.fromJson(json['wind'] as Map<String, dynamic>),
      moveEnergy: (json['moveEnergy'] as num).toInt(),
    );

Map<String, dynamic> _$TurnStartedDataToJson(TurnStartedData instance) =>
    <String, dynamic>{
      'turnIndex': instance.turnIndex,
      'currentPlayerId': instance.currentPlayerId,
      'wind': instance.wind,
      'moveEnergy': instance.moveEnergy,
    };

PlayerMovedData _$PlayerMovedDataFromJson(Map<String, dynamic> json) =>
    PlayerMovedData(
      playerId: json['playerId'] as String,
      position: Vector2Model.fromJson(json['position'] as Map<String, dynamic>),
      moveEnergy: (json['moveEnergy'] as num).toInt(),
    );

Map<String, dynamic> _$PlayerMovedDataToJson(PlayerMovedData instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'position': instance.position,
      'moveEnergy': instance.moveEnergy,
    };
