// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mission _$MissionFromJson(Map<String, dynamic> json) => Mission(
  missionId: json['missionId'] as String,
  type: json['type'] as String,
  target: json['target'] as String,
  requiredValue: (json['requiredValue'] as num).toInt(),
  currentValue: (json['currentValue'] as num).toInt(),
  rewardCoin: (json['rewardCoin'] as num).toInt(),
  rewardGem: (json['rewardGem'] as num).toInt(),
  rewardItems: (json['rewardItems'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isClaimed: json['isClaimed'] as bool,
);

Map<String, dynamic> _$MissionToJson(Mission instance) => <String, dynamic>{
  'missionId': instance.missionId,
  'type': instance.type,
  'target': instance.target,
  'requiredValue': instance.requiredValue,
  'currentValue': instance.currentValue,
  'rewardCoin': instance.rewardCoin,
  'rewardGem': instance.rewardGem,
  'rewardItems': instance.rewardItems,
  'isClaimed': instance.isClaimed,
};

ClaimResponse _$ClaimResponseFromJson(Map<String, dynamic> json) =>
    ClaimResponse(
      rewardCoin: (json['rewardCoin'] as num).toInt(),
      rewardGem: (json['rewardGem'] as num).toInt(),
      missionId: json['missionId'] as String,
    );

Map<String, dynamic> _$ClaimResponseToJson(ClaimResponse instance) =>
    <String, dynamic>{
      'rewardCoin': instance.rewardCoin,
      'rewardGem': instance.rewardGem,
      'missionId': instance.missionId,
    };
