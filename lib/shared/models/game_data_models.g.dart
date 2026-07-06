// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_data_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpawnPoint _$SpawnPointFromJson(Map<String, dynamic> json) => SpawnPoint(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
);

Map<String, dynamic> _$SpawnPointToJson(SpawnPoint instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

CharacterData _$CharacterDataFromJson(Map<String, dynamic> json) =>
    CharacterData(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      weaponId: json['weaponId'] as String,
      skillId: json['skillId'] as String,
      hp: (json['hp'] as num).toInt(),
      damage: (json['damage'] as num).toInt(),
      mobility: (json['mobility'] as num).toInt(),
      defense: (json['defense'] as num).toInt(),
      skillPower: (json['skillPower'] as num).toInt(),
      terrainDamage: (json['terrainDamage'] as num).toInt(),
      difficulty: (json['difficulty'] as num).toInt(),
    );

Map<String, dynamic> _$CharacterDataToJson(CharacterData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
      'weaponId': instance.weaponId,
      'skillId': instance.skillId,
      'hp': instance.hp,
      'damage': instance.damage,
      'mobility': instance.mobility,
      'defense': instance.defense,
      'skillPower': instance.skillPower,
      'terrainDamage': instance.terrainDamage,
      'difficulty': instance.difficulty,
    };

WeaponData _$WeaponDataFromJson(Map<String, dynamic> json) => WeaponData(
  id: json['id'] as String,
  name: json['name'] as String,
  damage: (json['damage'] as num).toInt(),
  explosionRadius: (json['explosionRadius'] as num).toInt(),
  terrainDamage: (json['terrainDamage'] as num).toInt(),
  projectileWeight: (json['projectileWeight'] as num).toDouble(),
  windInfluence: (json['windInfluence'] as num).toDouble(),
  multiHit: (json['multiHit'] as num).toInt(),
);

Map<String, dynamic> _$WeaponDataToJson(WeaponData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'damage': instance.damage,
      'explosionRadius': instance.explosionRadius,
      'terrainDamage': instance.terrainDamage,
      'projectileWeight': instance.projectileWeight,
      'windInfluence': instance.windInfluence,
      'multiHit': instance.multiHit,
    };

SkillData _$SkillDataFromJson(Map<String, dynamic> json) => SkillData(
  id: json['id'] as String,
  name: json['name'] as String,
  characterId: json['characterId'] as String,
  cooldown: (json['cooldown'] as num).toInt(),
  effect: json['effect'] as String,
  projectileCount: (json['projectileCount'] as num).toInt(),
  damageMultiplier: (json['damageMultiplier'] as num).toDouble(),
  statusEffect: json['statusEffect'] as String?,
);

Map<String, dynamic> _$SkillDataToJson(SkillData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'characterId': instance.characterId,
  'cooldown': instance.cooldown,
  'effect': instance.effect,
  'projectileCount': instance.projectileCount,
  'damageMultiplier': instance.damageMultiplier,
  'statusEffect': instance.statusEffect,
};

ItemData _$ItemDataFromJson(Map<String, dynamic> json) => ItemData(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  target: json['target'] as String,
  value: (json['value'] as num).toDouble(),
  maxUsesPerMatch: (json['maxUsesPerMatch'] as num).toInt(),
);

Map<String, dynamic> _$ItemDataToJson(ItemData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'target': instance.target,
  'value': instance.value,
  'maxUsesPerMatch': instance.maxUsesPerMatch,
};

MapData _$MapDataFromJson(Map<String, dynamic> json) => MapData(
  id: json['id'] as String,
  name: json['name'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  windRange: (json['windRange'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  spawnPoints: (json['spawnPoints'] as List<dynamic>)
      .map((e) => SpawnPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MapDataToJson(MapData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'width': instance.width,
  'height': instance.height,
  'windRange': instance.windRange,
  'spawnPoints': instance.spawnPoints,
};

GameData _$GameDataFromJson(Map<String, dynamic> json) => GameData(
  characters: (json['characters'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, CharacterData.fromJson(e as Map<String, dynamic>)),
  ),
  weapons: (json['weapons'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, WeaponData.fromJson(e as Map<String, dynamic>)),
  ),
  skills: (json['skills'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, SkillData.fromJson(e as Map<String, dynamic>)),
  ),
  items: (json['items'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, ItemData.fromJson(e as Map<String, dynamic>)),
  ),
  maps: (json['maps'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, MapData.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$GameDataToJson(GameData instance) => <String, dynamic>{
  'characters': instance.characters,
  'weapons': instance.weapons,
  'skills': instance.skills,
  'items': instance.items,
  'maps': instance.maps,
};
