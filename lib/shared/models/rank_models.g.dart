// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerRank _$PlayerRankFromJson(Map<String, dynamic> json) => PlayerRank(
  playerId: json['playerId'] as String,
  displayName: json['displayName'] as String,
  seasonId: json['seasonId'] as String,
  rating: (json['rating'] as num).toInt(),
  tier: json['tier'] as String,
  division: (json['division'] as num).toInt(),
  wins: (json['wins'] as num).toInt(),
  losses: (json['losses'] as num).toInt(),
  draws: (json['draws'] as num).toInt(),
  winStreak: (json['winStreak'] as num).toInt(),
  highestTier: json['highestTier'] as String?,
  updatedAt: json['updatedAt'] as String,
  rankPos: (json['rankPos'] as num?)?.toInt(),
);

Map<String, dynamic> _$PlayerRankToJson(PlayerRank instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'displayName': instance.displayName,
      'seasonId': instance.seasonId,
      'rating': instance.rating,
      'tier': instance.tier,
      'division': instance.division,
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'winStreak': instance.winStreak,
      'highestTier': instance.highestTier,
      'updatedAt': instance.updatedAt,
      'rankPos': instance.rankPos,
    };

Season _$SeasonFromJson(Map<String, dynamic> json) => Season(
  seasonId: json['seasonId'] as String,
  name: json['name'] as String,
  startsAt: json['startsAt'] as String,
  endsAt: json['endsAt'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$SeasonToJson(Season instance) => <String, dynamic>{
  'seasonId': instance.seasonId,
  'name': instance.name,
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'status': instance.status,
};
