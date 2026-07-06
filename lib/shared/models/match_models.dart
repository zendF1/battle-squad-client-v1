import 'package:json_annotation/json_annotation.dart';

part 'match_models.g.dart';

@JsonSerializable()
class Vector2Model {
  final double x;
  final double y;

  Vector2Model({
    required this.x,
    required this.y,
  });

  factory Vector2Model.fromJson(Map<String, dynamic> json) =>
      _$Vector2ModelFromJson(json);
  Map<String, dynamic> toJson() => _$Vector2ModelToJson(this);
}

@JsonSerializable()
class WindState {
  final int direction;
  final int power;

  WindState({
    required this.direction,
    required this.power,
  });

  factory WindState.fromJson(Map<String, dynamic> json) =>
      _$WindStateFromJson(json);
  Map<String, dynamic> toJson() => _$WindStateToJson(this);
}

@JsonSerializable()
class StatusEffect {
  final String effectId;
  final String targetPlayerId;
  final int durationTurn;
  final double value;
  final String sourcePlayerId;

  StatusEffect({
    required this.effectId,
    required this.targetPlayerId,
    required this.durationTurn,
    required this.value,
    required this.sourcePlayerId,
  });

  factory StatusEffect.fromJson(Map<String, dynamic> json) =>
      _$StatusEffectFromJson(json);
  Map<String, dynamic> toJson() => _$StatusEffectToJson(this);
}

@JsonSerializable()
class BattlePlayerState {
  final String playerId;
  final String displayName;
  final int teamId;
  final String characterId;
  final int hp;
  final int maxHp;
  final int defense;
  final Vector2Model position;
  final int moveEnergy;
  final List<String> items;
  final List<StatusEffect> statusEffects;
  final bool isAlive;
  final bool isBot;
  final int skillCooldown;
  final int damageDealt;
  final int killCount;
  final int shotsFired;
  final int shotsHit;

  BattlePlayerState({
    required this.playerId,
    required this.displayName,
    required this.teamId,
    required this.characterId,
    required this.hp,
    required this.maxHp,
    required this.defense,
    required this.position,
    required this.moveEnergy,
    required this.items,
    required this.statusEffects,
    required this.isAlive,
    required this.isBot,
    required this.skillCooldown,
    required this.damageDealt,
    required this.killCount,
    required this.shotsFired,
    required this.shotsHit,
  });

  factory BattlePlayerState.fromJson(Map<String, dynamic> json) =>
      _$BattlePlayerStateFromJson(json);
  Map<String, dynamic> toJson() => _$BattlePlayerStateToJson(this);
}

@JsonSerializable()
class ProjectileStep {
  final Vector2Model position;
  final Vector2Model velocity;
  final double time;

  ProjectileStep({
    required this.position,
    required this.velocity,
    required this.time,
  });

  factory ProjectileStep.fromJson(Map<String, dynamic> json) =>
      _$ProjectileStepFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectileStepToJson(this);
}

@JsonSerializable()
class ProjectileResult {
  final String projectileId;
  final String ownerPlayerId;
  final String? skillId;
  final List<ProjectileStep> path;
  final String? hitPlayerId;
  final Vector2Model? explosionPoint;
  final double explosionRadius;
  final bool terrainDestroyed;

  ProjectileResult({
    required this.projectileId,
    required this.ownerPlayerId,
    this.skillId,
    required this.path,
    this.hitPlayerId,
    this.explosionPoint,
    required this.explosionRadius,
    required this.terrainDestroyed,
  });

  factory ProjectileResult.fromJson(Map<String, dynamic> json) =>
      _$ProjectileResultFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectileResultToJson(this);
}

@JsonSerializable()
class DamageEntry {
  final String playerId;
  final int damage;
  final int hp;
  final bool isAlive;
  final String? type;

  DamageEntry({
    required this.playerId,
    required this.damage,
    required this.hp,
    required this.isAlive,
    this.type,
  });

  factory DamageEntry.fromJson(Map<String, dynamic> json) =>
      _$DamageEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DamageEntryToJson(this);
}

@JsonSerializable()
class MatchState {
  final String matchId;
  final String roomId;
  final String mode;
  final String mapId;
  final int turnIndex;
  final String currentPlayerId;
  final WindState wind;
  final Map<String, BattlePlayerState> players;
  final String status;
  final List<String> turnOrder;
  final int turnTimeLeft;
  final List<StatusEffect> activeEffects;

  MatchState({
    required this.matchId,
    required this.roomId,
    required this.mode,
    required this.mapId,
    required this.turnIndex,
    required this.currentPlayerId,
    required this.wind,
    required this.players,
    required this.status,
    required this.turnOrder,
    required this.turnTimeLeft,
    required this.activeEffects,
  });

  factory MatchState.fromJson(Map<String, dynamic> json) =>
      _$MatchStateFromJson(json);
  Map<String, dynamic> toJson() => _$MatchStateToJson(this);
}

@JsonSerializable()
class MatchReward {
  final int exp;
  final int coins;
  final int? gemReward;

  MatchReward({
    required this.exp,
    required this.coins,
    this.gemReward,
  });

  factory MatchReward.fromJson(Map<String, dynamic> json) =>
      _$MatchRewardFromJson(json);
  Map<String, dynamic> toJson() => _$MatchRewardToJson(this);
}

@JsonSerializable()
class MatchEndedData {
  final int winningTeam;
  final Map<String, MatchReward>? rewards;
  final String? result;
  final String? message;

  MatchEndedData({
    required this.winningTeam,
    this.rewards,
    this.result,
    this.message,
  });

  factory MatchEndedData.fromJson(Map<String, dynamic> json) =>
      _$MatchEndedDataFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEndedDataToJson(this);
}

@JsonSerializable()
class TurnStartedData {
  final int turnIndex;
  final String currentPlayerId;
  final WindState wind;
  final int moveEnergy;

  TurnStartedData({
    required this.turnIndex,
    required this.currentPlayerId,
    required this.wind,
    required this.moveEnergy,
  });

  factory TurnStartedData.fromJson(Map<String, dynamic> json) =>
      _$TurnStartedDataFromJson(json);
  Map<String, dynamic> toJson() => _$TurnStartedDataToJson(this);
}

@JsonSerializable()
class PlayerMovedData {
  final String playerId;
  final Vector2Model position;
  final int moveEnergy;

  PlayerMovedData({
    required this.playerId,
    required this.position,
    required this.moveEnergy,
  });

  factory PlayerMovedData.fromJson(Map<String, dynamic> json) =>
      _$PlayerMovedDataFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerMovedDataToJson(this);
}
