import 'package:json_annotation/json_annotation.dart';

part 'player_models.g.dart';

@JsonSerializable()
class PlayerProfile {
  final String playerId;
  final String accountId;
  final String displayName;
  final int level;
  final int exp;
  final int coin;
  final int gem;
  final String createdAt;
  final String lastLoginAt;

  PlayerProfile({
    required this.playerId,
    required this.accountId,
    required this.displayName,
    required this.level,
    required this.exp,
    required this.coin,
    required this.gem,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) =>
      _$PlayerProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerProfileToJson(this);
}

@JsonSerializable()
class InventoryItem {
  final String playerId;
  final String itemId;
  final int quantity;
  final String source;
  final String acquiredAt;
  final String? expiresAt;

  InventoryItem({
    required this.playerId,
    required this.itemId,
    required this.quantity,
    required this.source,
    required this.acquiredAt,
    this.expiresAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);
}

@JsonSerializable()
class MatchHistoryEntry {
  final String matchId;
  final String mode;
  final String mapId;
  final String result;
  final int expGained;
  final int coinGained;
  final String playedAt;

  MatchHistoryEntry({
    required this.matchId,
    required this.mode,
    required this.mapId,
    required this.result,
    required this.expGained,
    required this.coinGained,
    required this.playedAt,
  });

  factory MatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$MatchHistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MatchHistoryEntryToJson(this);
}
