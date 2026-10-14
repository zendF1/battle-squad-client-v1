import 'package:json_annotation/json_annotation.dart';

part 'character_progression_models.g.dart';

@JsonSerializable()
class PlayerCharacter {
  final String playerId;
  final String characterId;
  final int level;
  final int exp;
  final int? nextLevelExp;
  final bool isMaxLevel;
  final int statPoints;
  final int bonusHp;
  final int bonusDamage;
  final int bonusMobility;
  final int bonusDefense;
  final int bonusSkillPower;
  final int bonusTerrainDmg;
  final String unlockedAt;

  PlayerCharacter({
    required this.playerId,
    required this.characterId,
    required this.level,
    required this.exp,
    this.nextLevelExp,
    required this.isMaxLevel,
    required this.statPoints,
    required this.bonusHp,
    required this.bonusDamage,
    required this.bonusMobility,
    required this.bonusDefense,
    required this.bonusSkillPower,
    required this.bonusTerrainDmg,
    required this.unlockedAt,
  });

  factory PlayerCharacter.fromJson(Map<String, dynamic> json) =>
      _$PlayerCharacterFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerCharacterToJson(this);

  int get totalBonusSpent =>
      bonusHp + bonusDamage + bonusMobility + bonusDefense + bonusSkillPower + bonusTerrainDmg;
}
