import 'package:json_annotation/json_annotation.dart';

part 'game_data_models.g.dart';

@JsonSerializable()
class SpawnPoint {
  final double x;
  final double y;

  SpawnPoint({
    required this.x,
    required this.y,
  });

  factory SpawnPoint.fromJson(Map<String, dynamic> json) =>
      _$SpawnPointFromJson(json);
  Map<String, dynamic> toJson() => _$SpawnPointToJson(this);
}

@JsonSerializable()
class CharacterData {
  final String id;
  final String name;
  final String role;
  final String weaponId;
  final String skillId;
  final int hp;
  final int damage;
  final int mobility;
  final int defense;
  final int skillPower;
  final int terrainDamage;
  final int difficulty;

  CharacterData({
    required this.id,
    required this.name,
    required this.role,
    required this.weaponId,
    required this.skillId,
    required this.hp,
    required this.damage,
    required this.mobility,
    required this.defense,
    required this.skillPower,
    required this.terrainDamage,
    required this.difficulty,
  });

  factory CharacterData.fromJson(Map<String, dynamic> json) =>
      _$CharacterDataFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterDataToJson(this);
}

@JsonSerializable()
class WeaponData {
  final String id;
  final String name;
  final int damage;
  final int explosionRadius;
  final int terrainDamage;
  final double projectileWeight;
  final double windInfluence;
  final int multiHit;

  WeaponData({
    required this.id,
    required this.name,
    required this.damage,
    required this.explosionRadius,
    required this.terrainDamage,
    required this.projectileWeight,
    required this.windInfluence,
    required this.multiHit,
  });

  factory WeaponData.fromJson(Map<String, dynamic> json) =>
      _$WeaponDataFromJson(json);
  Map<String, dynamic> toJson() => _$WeaponDataToJson(this);
}

@JsonSerializable()
class SkillData {
  final String id;
  final String name;
  final String characterId;
  final int cooldown;
  final String effect;
  final int projectileCount;
  final double damageMultiplier;
  final String? statusEffect;

  SkillData({
    required this.id,
    required this.name,
    required this.characterId,
    required this.cooldown,
    required this.effect,
    required this.projectileCount,
    required this.damageMultiplier,
    this.statusEffect,
  });

  factory SkillData.fromJson(Map<String, dynamic> json) =>
      _$SkillDataFromJson(json);
  Map<String, dynamic> toJson() => _$SkillDataToJson(this);
}

@JsonSerializable()
class ItemData {
  final String id;
  final String name;
  final String type;
  final String target;
  final double value;
  final int maxUsesPerMatch;

  ItemData({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.value,
    required this.maxUsesPerMatch,
  });

  factory ItemData.fromJson(Map<String, dynamic> json) =>
      _$ItemDataFromJson(json);
  Map<String, dynamic> toJson() => _$ItemDataToJson(this);
}

@JsonSerializable()
class MapData {
  final String id;
  final String name;
  final int width;
  final int height;
  final List<int> windRange;
  final List<SpawnPoint> spawnPoints;

  MapData({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.windRange,
    required this.spawnPoints,
  });

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
  Map<String, dynamic> toJson() => _$MapDataToJson(this);
}

@JsonSerializable()
class GameData {
  final Map<String, CharacterData> characters;
  final Map<String, WeaponData> weapons;
  final Map<String, SkillData> skills;
  final Map<String, ItemData> items;
  final Map<String, MapData> maps;

  GameData({
    required this.characters,
    required this.weapons,
    required this.skills,
    required this.items,
    required this.maps,
  });

  factory GameData.fromJson(Map<String, dynamic> json) =>
      _$GameDataFromJson(json);
  Map<String, dynamic> toJson() => _$GameDataToJson(this);
}
