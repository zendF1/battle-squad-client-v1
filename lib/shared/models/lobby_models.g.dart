// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LobbyMember _$LobbyMemberFromJson(Map<String, dynamic> json) => LobbyMember(
  playerId: json['playerId'] as String,
  displayName: json['displayName'] as String,
  characterId: json['characterId'] as String,
  items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
  rating: (json['rating'] as num).toInt(),
  tier: json['tier'] as String,
);

Map<String, dynamic> _$LobbyMemberToJson(LobbyMember instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'displayName': instance.displayName,
      'characterId': instance.characterId,
      'items': instance.items,
      'rating': instance.rating,
      'tier': instance.tier,
    };

LobbyState _$LobbyStateFromJson(Map<String, dynamic> json) => LobbyState(
  lobbyId: json['lobbyId'] as String,
  hostPlayerId: json['hostPlayerId'] as String,
  members: (json['members'] as List<dynamic>)
      .map((e) => LobbyMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String,
);

Map<String, dynamic> _$LobbyStateToJson(LobbyState instance) =>
    <String, dynamic>{
      'lobbyId': instance.lobbyId,
      'hostPlayerId': instance.hostPlayerId,
      'members': instance.members,
      'status': instance.status,
    };
