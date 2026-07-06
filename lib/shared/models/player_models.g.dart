// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerProfile _$PlayerProfileFromJson(Map<String, dynamic> json) =>
    PlayerProfile(
      playerId: json['playerId'] as String,
      accountId: json['accountId'] as String,
      displayName: json['displayName'] as String,
      level: (json['level'] as num).toInt(),
      exp: (json['exp'] as num).toInt(),
      coin: (json['coin'] as num).toInt(),
      gem: (json['gem'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String,
    );

Map<String, dynamic> _$PlayerProfileToJson(PlayerProfile instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'accountId': instance.accountId,
      'displayName': instance.displayName,
      'level': instance.level,
      'exp': instance.exp,
      'coin': instance.coin,
      'gem': instance.gem,
      'createdAt': instance.createdAt,
      'lastLoginAt': instance.lastLoginAt,
    };

InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    InventoryItem(
      playerId: json['playerId'] as String,
      itemId: json['itemId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      source: json['source'] as String,
      acquiredAt: json['acquiredAt'] as String,
      expiresAt: json['expiresAt'] as String?,
    );

Map<String, dynamic> _$InventoryItemToJson(InventoryItem instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'itemId': instance.itemId,
      'quantity': instance.quantity,
      'source': instance.source,
      'acquiredAt': instance.acquiredAt,
      'expiresAt': instance.expiresAt,
    };

MatchHistoryEntry _$MatchHistoryEntryFromJson(Map<String, dynamic> json) =>
    MatchHistoryEntry(
      matchId: json['matchId'] as String,
      mode: json['mode'] as String,
      mapId: json['mapId'] as String,
      result: json['result'] as String,
      expGained: (json['expGained'] as num).toInt(),
      coinGained: (json['coinGained'] as num).toInt(),
      playedAt: json['playedAt'] as String,
    );

Map<String, dynamic> _$MatchHistoryEntryToJson(MatchHistoryEntry instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'mode': instance.mode,
      'mapId': instance.mapId,
      'result': instance.result,
      'expGained': instance.expGained,
      'coinGained': instance.coinGained,
      'playedAt': instance.playedAt,
    };
