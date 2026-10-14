import 'package:json_annotation/json_annotation.dart';

part 'lobby_models.g.dart';

@JsonSerializable()
class LobbyMember {
  final String playerId;
  final String displayName;
  final String characterId;
  final List<String> items;
  final int rating;
  final String tier;

  LobbyMember({
    required this.playerId,
    required this.displayName,
    required this.characterId,
    required this.items,
    required this.rating,
    required this.tier,
  });

  factory LobbyMember.fromJson(Map<String, dynamic> json) =>
      _$LobbyMemberFromJson(json);
  Map<String, dynamic> toJson() => _$LobbyMemberToJson(this);
}

@JsonSerializable()
class LobbyState {
  final String lobbyId;
  final String hostPlayerId;
  final List<LobbyMember> members;
  final String status; // preparing, in_queue, in_match

  LobbyState({
    required this.lobbyId,
    required this.hostPlayerId,
    required this.members,
    required this.status,
  });

  factory LobbyState.fromJson(Map<String, dynamic> json) =>
      _$LobbyStateFromJson(json);
  Map<String, dynamic> toJson() => _$LobbyStateToJson(this);
}
