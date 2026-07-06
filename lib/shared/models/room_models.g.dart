// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomPlayer _$RoomPlayerFromJson(Map<String, dynamic> json) => RoomPlayer(
  playerId: json['playerId'] as String,
  displayName: json['displayName'] as String,
  teamId: (json['teamId'] as num).toInt(),
  characterId: json['characterId'] as String,
  items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
  isReady: json['isReady'] as bool,
  isHost: json['isHost'] as bool,
);

Map<String, dynamic> _$RoomPlayerToJson(RoomPlayer instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'displayName': instance.displayName,
      'teamId': instance.teamId,
      'characterId': instance.characterId,
      'items': instance.items,
      'isReady': instance.isReady,
      'isHost': instance.isHost,
    };

RoomState _$RoomStateFromJson(Map<String, dynamic> json) => RoomState(
  roomId: json['roomId'] as String,
  hostPlayerId: json['hostPlayerId'] as String,
  mode: json['mode'] as String,
  mapId: json['mapId'] as String,
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  players: (json['players'] as List<dynamic>)
      .map((e) => RoomPlayer.fromJson(e as Map<String, dynamic>))
      .toList(),
  isLocked: json['isLocked'] as bool,
  status: json['status'] as String,
);

Map<String, dynamic> _$RoomStateToJson(RoomState instance) => <String, dynamic>{
  'roomId': instance.roomId,
  'hostPlayerId': instance.hostPlayerId,
  'mode': instance.mode,
  'mapId': instance.mapId,
  'maxPlayers': instance.maxPlayers,
  'players': instance.players,
  'isLocked': instance.isLocked,
  'status': instance.status,
};

RoomListItem _$RoomListItemFromJson(Map<String, dynamic> json) => RoomListItem(
  roomId: json['roomId'] as String,
  hostPlayerId: json['hostPlayerId'] as String,
  mode: json['mode'] as String,
  mapId: json['mapId'] as String,
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  playerCount: (json['playerCount'] as num).toInt(),
  isLocked: json['isLocked'] as bool,
  status: json['status'] as String,
);

Map<String, dynamic> _$RoomListItemToJson(RoomListItem instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'hostPlayerId': instance.hostPlayerId,
      'mode': instance.mode,
      'mapId': instance.mapId,
      'maxPlayers': instance.maxPlayers,
      'playerCount': instance.playerCount,
      'isLocked': instance.isLocked,
      'status': instance.status,
    };
