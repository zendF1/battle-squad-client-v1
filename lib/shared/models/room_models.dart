import 'package:json_annotation/json_annotation.dart';

part 'room_models.g.dart';

@JsonSerializable()
class RoomPlayer {
  final String playerId;
  final String displayName;
  final int teamId;
  final String characterId;
  final List<String> items;
  final bool isReady;
  final bool isHost;

  RoomPlayer({
    required this.playerId,
    required this.displayName,
    required this.teamId,
    required this.characterId,
    required this.items,
    required this.isReady,
    required this.isHost,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> json) =>
      _$RoomPlayerFromJson(json);
  Map<String, dynamic> toJson() => _$RoomPlayerToJson(this);
}

@JsonSerializable()
class RoomState {
  final String roomId;
  final String hostPlayerId;
  final String mode;
  final String mapId;
  final int maxPlayers;
  final List<RoomPlayer> players;
  final bool isLocked;
  final String status;

  RoomState({
    required this.roomId,
    required this.hostPlayerId,
    required this.mode,
    required this.mapId,
    required this.maxPlayers,
    required this.players,
    required this.isLocked,
    required this.status,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) =>
      _$RoomStateFromJson(json);
  Map<String, dynamic> toJson() => _$RoomStateToJson(this);
}

@JsonSerializable()
class RoomListItem {
  final String roomId;
  final String hostPlayerId;
  final String mode;
  final String mapId;
  final int maxPlayers;
  final int playerCount;
  final bool isLocked;
  final String status;

  RoomListItem({
    required this.roomId,
    required this.hostPlayerId,
    required this.mode,
    required this.mapId,
    required this.maxPlayers,
    required this.playerCount,
    required this.isLocked,
    required this.status,
  });

  factory RoomListItem.fromJson(Map<String, dynamic> json) =>
      _$RoomListItemFromJson(json);
  Map<String, dynamic> toJson() => _$RoomListItemToJson(this);
}
