// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_progression_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerCharacter _$PlayerCharacterFromJson(Map<String, dynamic> json) =>
    PlayerCharacter(
      playerId: json['playerId'] as String,
      characterId: json['characterId'] as String,
      level: (json['level'] as num).toInt(),
      exp: (json['exp'] as num).toInt(),
      nextLevelExp: (json['nextLevelExp'] as num?)?.toInt(),
      isMaxLevel: json['isMaxLevel'] as bool,
      statPoints: (json['statPoints'] as num).toInt(),
      bonusHp: (json['bonusHp'] as num).toInt(),
      bonusDamage: (json['bonusDamage'] as num).toInt(),
      bonusMobility: (json['bonusMobility'] as num).toInt(),
      bonusDefense: (json['bonusDefense'] as num).toInt(),
      bonusSkillPower: (json['bonusSkillPower'] as num).toInt(),
      bonusTerrainDmg: (json['bonusTerrainDmg'] as num).toInt(),
      unlockedAt: json['unlockedAt'] as String,
    );

Map<String, dynamic> _$PlayerCharacterToJson(PlayerCharacter instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'characterId': instance.characterId,
      'level': instance.level,
      'exp': instance.exp,
      'nextLevelExp': instance.nextLevelExp,
      'isMaxLevel': instance.isMaxLevel,
      'statPoints': instance.statPoints,
      'bonusHp': instance.bonusHp,
      'bonusDamage': instance.bonusDamage,
      'bonusMobility': instance.bonusMobility,
      'bonusDefense': instance.bonusDefense,
      'bonusSkillPower': instance.bonusSkillPower,
      'bonusTerrainDmg': instance.bonusTerrainDmg,
      'unlockedAt': instance.unlockedAt,
    };
