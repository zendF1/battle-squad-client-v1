# Battle Squad Flutter Client — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full-featured Flutter mobile client for the Battle Squad turn-based artillery game, connecting to an existing Go server.

**Architecture:** Feature-first module structure with Riverpod state management, GoRouter navigation, Flame game engine for match rendering, Dio for REST API, and web_socket_channel for real-time WebSocket communication.

**Tech Stack:** Flutter 3.44+ / Dart 3.12+, Flame, Riverpod, GoRouter, Dio, web_socket_channel, flutter_secure_storage

---

## File Structure

```
lib/
├── main.dart                           # App entry, ProviderScope, MaterialApp.router
├── core/
│   ├── theme/
│   │   └── app_theme.dart              # Dark theme, colors, text styles
│   ├── api/
│   │   ├── api_client.dart             # Dio wrapper, base URL, error parsing
│   │   └── api_interceptor.dart        # JWT attach + auto-refresh on 401
│   ├── auth/
│   │   ├── token_storage.dart          # flutter_secure_storage wrapper
│   │   └── auth_provider.dart          # AuthNotifier: login, logout, refresh, state
│   ├── ws/
│   │   ├── ws_manager.dart             # WebSocket connect, reconnect, send, event stream
│   │   └── ws_events.dart              # Typed WS event classes + parser
│   ├── router/
│   │   └── app_router.dart             # GoRouter config, auth redirect, routes
│   └── providers/
│       └── core_providers.dart         # httpClient, wsManager, gameData providers
├── shared/
│   ├── models/
│   │   ├── auth_models.dart            # LoginRequest/Response, RefreshRequest/Response
│   │   ├── player_models.dart          # PlayerProfile, InventoryItem, MatchHistoryEntry
│   │   ├── room_models.dart            # RoomState, RoomPlayer
│   │   ├── match_models.dart           # MatchState, BattlePlayerState, WindState, etc.
│   │   ├── shop_models.dart            # ShopOffer, PurchaseRequest/Response
│   │   ├── mission_models.dart         # Mission, ClaimResponse
│   │   ├── rank_models.dart            # PlayerRank, LeaderboardEntry, Season
│   │   └── game_data_models.dart       # CharacterData, WeaponData, SkillData, ItemData, MapData
│   └── widgets/
│       ├── app_button.dart             # Styled game button
│       ├── app_card.dart               # Styled card
│       ├── loading_overlay.dart        # Full-screen loading
│       ├── error_snackbar.dart         # Error display helper
│       └── currency_display.dart       # Coin/Gem display widget
├── features/
│   ├── auth/
│   │   ├── splash_screen.dart          # Token check → redirect
│   │   └── login_screen.dart           # Guest login button
│   ├── lobby/
│   │   ├── lobby_screen.dart           # Room list + create/join
│   │   ├── lobby_provider.dart         # RoomList fetching
│   │   └── create_room_dialog.dart     # Mode, map, password selection
│   ├── room/
│   │   ├── room_screen.dart            # Waiting room UI
│   │   ├── room_provider.dart          # Room state from WS
│   │   ├── character_select.dart       # Character grid
│   │   └── item_select.dart            # Item picker
│   ├── match/
│   │   ├── match_screen.dart           # GameWidget + HUD overlays
│   │   ├── match_provider.dart         # Match state from WS events
│   │   ├── game/
│   │   │   ├── battle_game.dart        # FlameGame subclass
│   │   │   ├── terrain_component.dart  # Terrain generation + destruction + render
│   │   │   ├── player_component.dart   # Player sprite/shape
│   │   │   ├── projectile_component.dart # Projectile animation along path
│   │   │   └── explosion_component.dart  # Expanding circle effect
│   │   ├── hud/
│   │   │   ├── match_hud.dart          # Top bar + bottom controls
│   │   │   ├── angle_power_control.dart # Angle slider + power bar
│   │   │   ├── item_skill_bar.dart     # Item buttons + skill button
│   │   │   └── wind_indicator.dart     # Wind arrow + power
│   │   └── match_result_dialog.dart    # Win/Lose/Draw overlay
│   ├── profile/
│   │   ├── profile_screen.dart         # Profile tab
│   │   ├── profile_provider.dart       # Profile + inventory fetching
│   │   ├── inventory_grid.dart         # Item grid
│   │   └── match_history_list.dart     # Paginated history
│   ├── shop/
│   │   ├── shop_screen.dart            # Shop tab
│   │   └── shop_provider.dart          # Offers + purchase
│   ├── mission/
│   │   ├── mission_screen.dart         # Missions tab (daily + achievements)
│   │   └── mission_provider.dart       # Missions fetching + claim
│   ├── ranking/
│   │   ├── ranking_screen.dart         # Ranking tab
│   │   └── ranking_provider.dart       # Rank + leaderboard
│   └── settings/
│       └── settings_screen.dart        # Settings page
```

---

### Task 1: Project Setup & Dependencies

**Files:**
- Create: `pubspec.yaml` (via flutter create, then modify)
- Create: `analysis_options.yaml`
- Create: `lib/main.dart` (minimal)

- [ ] **Step 1: Create Flutter project**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter create --org com.battlesquad --project-name battle_squad_v1 --platforms ios,android .
```

- [ ] **Step 2: Update pubspec.yaml dependencies**

Replace the `dependencies` and `dev_dependencies` sections in `pubspec.yaml`:

```yaml
name: battle_squad_v1
description: Battle Squad - Turn-based artillery PvP game client
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter
  flame: ^1.21.0
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1
  dio: ^5.7.0
  web_socket_channel: ^3.0.2
  flutter_secure_storage: ^9.2.4
  device_info_plus: ^11.2.0
  uuid: ^4.5.1
  intl: ^0.20.2
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.14
  json_serializable: ^6.9.4
```

- [ ] **Step 3: Install dependencies**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter pub get
```

- [ ] **Step 4: Create minimal main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BattleSquadApp()));
}

class BattleSquadApp extends StatelessWidget {
  const BattleSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Squad',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(child: Text('Battle Squad')),
      ),
    );
  }
}
```

- [ ] **Step 5: Verify build**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
```

- [ ] **Step 6: Add .gitignore and commit**

Create `.gitignore` for Flutter project (flutter create should have generated one). Then:

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
git add -A
git commit -m "feat: initialize Flutter project with dependencies"
```

---

### Task 2: Shared Models

**Files:**
- Create: `lib/shared/models/auth_models.dart`
- Create: `lib/shared/models/player_models.dart`
- Create: `lib/shared/models/room_models.dart`
- Create: `lib/shared/models/match_models.dart`
- Create: `lib/shared/models/shop_models.dart`
- Create: `lib/shared/models/mission_models.dart`
- Create: `lib/shared/models/rank_models.dart`
- Create: `lib/shared/models/game_data_models.dart`

All models use `json_serializable` for JSON parsing. Each model file follows this pattern: class with `fromJson` factory + `toJson` method.

- [ ] **Step 1: Create auth models**

```dart
// lib/shared/models/auth_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String playerId;
  final String displayName;
  final int level;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.playerId,
    required this.displayName,
    required this.level,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RefreshResponse {
  final String accessToken;
  final String refreshToken;

  RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshResponseToJson(this);
}
```

- [ ] **Step 2: Create player models**

```dart
// lib/shared/models/player_models.dart
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
```

- [ ] **Step 3: Create room models**

```dart
// lib/shared/models/room_models.dart
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
```

- [ ] **Step 4: Create match models**

```dart
// lib/shared/models/match_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'match_models.g.dart';

@JsonSerializable()
class Vector2Model {
  final double x;
  final double y;

  Vector2Model({required this.x, required this.y});

  factory Vector2Model.fromJson(Map<String, dynamic> json) =>
      _$Vector2ModelFromJson(json);
  Map<String, dynamic> toJson() => _$Vector2ModelToJson(this);
}

@JsonSerializable()
class WindState {
  final int direction;
  final int power;

  WindState({required this.direction, required this.power});

  factory WindState.fromJson(Map<String, dynamic> json) =>
      _$WindStateFromJson(json);
  Map<String, dynamic> toJson() => _$WindStateToJson(this);
}

@JsonSerializable()
class StatusEffect {
  final String effectId;
  final String targetPlayerId;
  final int durationTurn;
  final double value;
  final String sourcePlayerId;

  StatusEffect({
    required this.effectId,
    required this.targetPlayerId,
    required this.durationTurn,
    required this.value,
    required this.sourcePlayerId,
  });

  factory StatusEffect.fromJson(Map<String, dynamic> json) =>
      _$StatusEffectFromJson(json);
  Map<String, dynamic> toJson() => _$StatusEffectToJson(this);
}

@JsonSerializable()
class BattlePlayerState {
  final String playerId;
  final String displayName;
  final int teamId;
  final String characterId;
  final int hp;
  final int maxHp;
  final int defense;
  final Vector2Model position;
  final int moveEnergy;
  final List<String> items;
  final List<StatusEffect> statusEffects;
  final bool isAlive;
  final bool isBot;
  final int skillCooldown;
  final int damageDealt;
  final int killCount;
  final int shotsFired;
  final int shotsHit;

  BattlePlayerState({
    required this.playerId,
    required this.displayName,
    required this.teamId,
    required this.characterId,
    required this.hp,
    required this.maxHp,
    required this.defense,
    required this.position,
    required this.moveEnergy,
    required this.items,
    required this.statusEffects,
    required this.isAlive,
    required this.isBot,
    required this.skillCooldown,
    required this.damageDealt,
    required this.killCount,
    required this.shotsFired,
    required this.shotsHit,
  });

  factory BattlePlayerState.fromJson(Map<String, dynamic> json) =>
      _$BattlePlayerStateFromJson(json);
  Map<String, dynamic> toJson() => _$BattlePlayerStateToJson(this);
}

@JsonSerializable()
class ProjectileStep {
  final Vector2Model position;
  final Vector2Model velocity;
  final double time;

  ProjectileStep({
    required this.position,
    required this.velocity,
    required this.time,
  });

  factory ProjectileStep.fromJson(Map<String, dynamic> json) =>
      _$ProjectileStepFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectileStepToJson(this);
}

@JsonSerializable()
class ProjectileResult {
  final String projectileId;
  final String ownerPlayerId;
  final String? skillId;
  final List<ProjectileStep> path;
  final String? hitPlayerId;
  final Vector2Model? explosionPoint;
  final double explosionRadius;
  final bool terrainDestroyed;

  ProjectileResult({
    required this.projectileId,
    required this.ownerPlayerId,
    this.skillId,
    required this.path,
    this.hitPlayerId,
    this.explosionPoint,
    required this.explosionRadius,
    required this.terrainDestroyed,
  });

  factory ProjectileResult.fromJson(Map<String, dynamic> json) =>
      _$ProjectileResultFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectileResultToJson(this);
}

@JsonSerializable()
class DamageEntry {
  final String playerId;
  final int damage;
  final int hp;
  final bool isAlive;
  final String? type;

  DamageEntry({
    required this.playerId,
    required this.damage,
    required this.hp,
    required this.isAlive,
    this.type,
  });

  factory DamageEntry.fromJson(Map<String, dynamic> json) =>
      _$DamageEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DamageEntryToJson(this);
}

@JsonSerializable()
class MatchState {
  final String matchId;
  final String roomId;
  final String mode;
  final String mapId;
  final int turnIndex;
  final String currentPlayerId;
  final WindState wind;
  final Map<String, BattlePlayerState> players;
  final String status;
  final List<String> turnOrder;
  final int turnTimeLeft;
  final List<StatusEffect> activeEffects;

  MatchState({
    required this.matchId,
    required this.roomId,
    required this.mode,
    required this.mapId,
    required this.turnIndex,
    required this.currentPlayerId,
    required this.wind,
    required this.players,
    required this.status,
    required this.turnOrder,
    required this.turnTimeLeft,
    required this.activeEffects,
  });

  factory MatchState.fromJson(Map<String, dynamic> json) =>
      _$MatchStateFromJson(json);
  Map<String, dynamic> toJson() => _$MatchStateToJson(this);
}

@JsonSerializable()
class MatchEndedData {
  final int winningTeam;
  final Map<String, MatchReward>? rewards;
  final String? result;
  final String? message;

  MatchEndedData({
    required this.winningTeam,
    this.rewards,
    this.result,
    this.message,
  });

  factory MatchEndedData.fromJson(Map<String, dynamic> json) =>
      _$MatchEndedDataFromJson(json);
  Map<String, dynamic> toJson() => _$MatchEndedDataToJson(this);
}

@JsonSerializable()
class MatchReward {
  final int exp;
  final int coins;
  final int? gemReward;

  MatchReward({required this.exp, required this.coins, this.gemReward});

  factory MatchReward.fromJson(Map<String, dynamic> json) =>
      _$MatchRewardFromJson(json);
  Map<String, dynamic> toJson() => _$MatchRewardToJson(this);
}

@JsonSerializable()
class TurnStartedData {
  final int turnIndex;
  final String currentPlayerId;
  final WindState wind;
  final int moveEnergy;

  TurnStartedData({
    required this.turnIndex,
    required this.currentPlayerId,
    required this.wind,
    required this.moveEnergy,
  });

  factory TurnStartedData.fromJson(Map<String, dynamic> json) =>
      _$TurnStartedDataFromJson(json);
  Map<String, dynamic> toJson() => _$TurnStartedDataToJson(this);
}

@JsonSerializable()
class PlayerMovedData {
  final String playerId;
  final Vector2Model position;
  final int moveEnergy;

  PlayerMovedData({
    required this.playerId,
    required this.position,
    required this.moveEnergy,
  });

  factory PlayerMovedData.fromJson(Map<String, dynamic> json) =>
      _$PlayerMovedDataFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerMovedDataToJson(this);
}
```

- [ ] **Step 5: Create shop models**

```dart
// lib/shared/models/shop_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'shop_models.g.dart';

@JsonSerializable()
class ShopOffer {
  final String offerId;
  final String itemId;
  final String offerType;
  final String priceCurrency;
  final int priceAmount;
  final int quantity;
  final int? limitPerPlayer;
  final bool isActive;

  ShopOffer({
    required this.offerId,
    required this.itemId,
    required this.offerType,
    required this.priceCurrency,
    required this.priceAmount,
    required this.quantity,
    this.limitPerPlayer,
    required this.isActive,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) =>
      _$ShopOfferFromJson(json);
  Map<String, dynamic> toJson() => _$ShopOfferToJson(this);
}

@JsonSerializable()
class PurchaseResponse {
  final String purchaseId;
  final String playerId;
  final String offerId;
  final String priceCurrency;
  final int priceAmount;
  final int quantityGranted;
  final String status;
  final String createdAt;

  PurchaseResponse({
    required this.purchaseId,
    required this.playerId,
    required this.offerId,
    required this.priceCurrency,
    required this.priceAmount,
    required this.quantityGranted,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseResponseToJson(this);
}
```

- [ ] **Step 6: Create mission models**

```dart
// lib/shared/models/mission_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'mission_models.g.dart';

@JsonSerializable()
class Mission {
  final String missionId;
  final String type;
  final String target;
  final int requiredValue;
  final int currentValue;
  final int rewardCoin;
  final int rewardGem;
  final List<String> rewardItems;
  final bool isClaimed;

  Mission({
    required this.missionId,
    required this.type,
    required this.target,
    required this.requiredValue,
    required this.currentValue,
    required this.rewardCoin,
    required this.rewardGem,
    required this.rewardItems,
    required this.isClaimed,
  });

  factory Mission.fromJson(Map<String, dynamic> json) =>
      _$MissionFromJson(json);
  Map<String, dynamic> toJson() => _$MissionToJson(this);
}

@JsonSerializable()
class ClaimResponse {
  final int rewardCoin;
  final int rewardGem;
  final String missionId;

  ClaimResponse({
    required this.rewardCoin,
    required this.rewardGem,
    required this.missionId,
  });

  factory ClaimResponse.fromJson(Map<String, dynamic> json) =>
      _$ClaimResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ClaimResponseToJson(this);
}
```

- [ ] **Step 7: Create rank models**

```dart
// lib/shared/models/rank_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'rank_models.g.dart';

@JsonSerializable()
class PlayerRank {
  final String playerId;
  final String displayName;
  final String seasonId;
  final int rating;
  final String tier;
  final int division;
  final int wins;
  final int losses;
  final int draws;
  final int winStreak;
  final String? highestTier;
  final String updatedAt;
  final int? rankPos;

  PlayerRank({
    required this.playerId,
    required this.displayName,
    required this.seasonId,
    required this.rating,
    required this.tier,
    required this.division,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winStreak,
    this.highestTier,
    required this.updatedAt,
    this.rankPos,
  });

  factory PlayerRank.fromJson(Map<String, dynamic> json) =>
      _$PlayerRankFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerRankToJson(this);
}

@JsonSerializable()
class Season {
  final String seasonId;
  final String name;
  final String startsAt;
  final String endsAt;
  final String status;

  Season({
    required this.seasonId,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  factory Season.fromJson(Map<String, dynamic> json) =>
      _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);
}
```

- [ ] **Step 8: Create game data models**

```dart
// lib/shared/models/game_data_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'game_data_models.g.dart';

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
class SpawnPoint {
  final double x;
  final double y;

  SpawnPoint({required this.x, required this.y});

  factory SpawnPoint.fromJson(Map<String, dynamic> json) =>
      _$SpawnPointFromJson(json);
  Map<String, dynamic> toJson() => _$SpawnPointToJson(this);
}
```

- [ ] **Step 9: Run code generation**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 10: Verify and commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/shared/
git commit -m "feat: add all shared data models with JSON serialization"
```

---

### Task 3: Theme & Shared Widgets

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/shared/widgets/app_button.dart`
- Create: `lib/shared/widgets/app_card.dart`
- Create: `lib/shared/widgets/loading_overlay.dart`
- Create: `lib/shared/widgets/error_snackbar.dart`
- Create: `lib/shared/widgets/currency_display.dart`

- [ ] **Step 1: Create app theme**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF1A1A2E);
  static const surface = Color(0xFF16213E);
  static const primary = Color(0xFF0F3460);
  static const accent = Color(0xFFE94560);
  static const textPrimary = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFF9E9E9E);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE94560);
  static const coin = Color(0xFFFFD700);
  static const gem = Color(0xFF9C27B0);

  // Team colors
  static const team1 = Color(0xFF2196F3);
  static const team2 = Color(0xFFFF5722);

  // Character colors
  static const rookie = Color(0xFF42A5F5);
  static const tanko = Color(0xFFEF5350);
  static const spark = Color(0xFFFFEE58);
  static const flora = Color(0xFF66BB6A);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          color: AppColors.surface,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );

  static Color characterColor(String characterId) {
    return switch (characterId) {
      'rookie' => AppColors.rookie,
      'tanko' => AppColors.tanko,
      'spark' => AppColors.spark,
      'flora' => AppColors.flora,
      _ => AppColors.textSecondary,
    };
  }

  static Color teamColor(int teamId) {
    return teamId == 1 ? AppColors.team1 : AppColors.team2;
  }
}
```

- [ ] **Step 2: Create shared widgets**

```dart
// lib/shared/widgets/app_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: color != null
          ? ElevatedButton.styleFrom(backgroundColor: color)
          : null,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}
```

```dart
// lib/shared/widgets/app_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
```

```dart
// lib/shared/widgets/loading_overlay.dart
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
```

```dart
// lib/shared/widgets/error_snackbar.dart
import 'package:flutter/material.dart';

void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
```

```dart
// lib/shared/widgets/currency_display.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CurrencyDisplay extends StatelessWidget {
  final int coins;
  final int gems;

  const CurrencyDisplay({
    super.key,
    required this.coins,
    required this.gems,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, color: AppColors.coin, size: 18),
        const SizedBox(width: 4),
        Text('$coins', style: const TextStyle(color: AppColors.coin)),
        const SizedBox(width: 12),
        const Icon(Icons.diamond, color: AppColors.gem, size: 18),
        const SizedBox(width: 4),
        Text('$gems', style: const TextStyle(color: AppColors.gem)),
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
git add lib/core/theme/ lib/shared/widgets/
git commit -m "feat: add dark theme and shared widgets"
```

---

### Task 4: API Client & Auth Interceptor

**Files:**
- Create: `lib/core/api/api_client.dart`
- Create: `lib/core/api/api_interceptor.dart`
- Create: `lib/core/auth/token_storage.dart`
- Test: `test/core/api/api_client_test.dart`

- [ ] **Step 1: Create token storage**

```dart
// lib/core/auth/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _playerIdKey = 'player_id';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  Future<String?> get playerId => _storage.read(key: _playerIdKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String playerId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _playerIdKey, value: playerId),
    ]);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> get hasTokens async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }
}
```

- [ ] **Step 2: Create API client**

```dart
// lib/core/api/api_client.dart
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException($code): $message';

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      final err = data['error'];
      return ApiException(
        code: err['code'] ?? 'UNKNOWN',
        message: err['message'] ?? 'Unknown error',
        statusCode: error.response?.statusCode ?? 0,
      );
    }
    return ApiException(
      code: 'NETWORK_ERROR',
      message: error.message ?? 'Network error',
      statusCode: error.response?.statusCode ?? 0,
    );
  }
}

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl, List<Interceptor>? interceptors})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        )) {
    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
```

- [ ] **Step 3: Create auth interceptor**

```dart
// lib/core/api/api_interceptor.dart
import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Future<void> Function() _onRefreshFailed;
  final Dio _refreshDio;
  bool _isRefreshing = false;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required String baseUrl,
    required Future<void> Function() onRefreshFailed,
  })  : _tokenStorage = tokenStorage,
        _onRefreshFailed = onRefreshFailed,
        _refreshDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _tokenStorage.refreshToken;
        if (refreshToken == null) {
          await _onRefreshFailed();
          _isRefreshing = false;
          return handler.next(err);
        }

        final response = await _refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final data = response.data as Map<String, dynamic>;
        final playerId = await _tokenStorage.playerId;
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          playerId: playerId ?? '',
        );

        // Retry the original request
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer ${data['accessToken']}';
        final retryResponse = await _refreshDio.fetch(options);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (_) {
        _isRefreshing = false;
        await _onRefreshFailed();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
```

- [ ] **Step 4: Write test for ApiException parsing**

```dart
// test/core/api/api_client_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_squad_v1/core/api/api_client.dart';

void main() {
  group('ApiException', () {
    test('parses server error response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {
            'error': {
              'code': 'BAD_REQUEST',
              'message': 'Invalid input',
            }
          },
        ),
      );

      final apiError = ApiException.fromDioError(error);
      expect(apiError.code, 'BAD_REQUEST');
      expect(apiError.message, 'Invalid input');
      expect(apiError.statusCode, 400);
    });

    test('handles network error without response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'Connection timeout',
      );

      final apiError = ApiException.fromDioError(error);
      expect(apiError.code, 'NETWORK_ERROR');
      expect(apiError.statusCode, 0);
    });
  });
}
```

- [ ] **Step 5: Run tests and commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter test test/core/api/api_client_test.dart
git add lib/core/api/ lib/core/auth/token_storage.dart test/
git commit -m "feat: add API client with auth interceptor and token storage"
```

---

### Task 5: WebSocket Manager

**Files:**
- Create: `lib/core/ws/ws_events.dart`
- Create: `lib/core/ws/ws_manager.dart`
- Test: `test/core/ws/ws_events_test.dart`

- [ ] **Step 1: Create WS event types**

```dart
// lib/core/ws/ws_events.dart
import '../../../shared/models/room_models.dart';
import '../../../shared/models/match_models.dart';

class WsEnvelope {
  final String event;
  final Map<String, dynamic> data;

  WsEnvelope({required this.event, required this.data});

  factory WsEnvelope.fromJson(Map<String, dynamic> json) {
    return WsEnvelope(
      event: json['event'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {'event': event, 'data': data};
}

sealed class WsEvent {}

// Room events
class RoomUpdatedEvent extends WsEvent {
  final RoomState room;
  RoomUpdatedEvent(this.room);
}

class RoomErrorEvent extends WsEvent {
  final String code;
  final String message;
  RoomErrorEvent({required this.code, required this.message});
}

// Match events
class MatchStartedEvent extends WsEvent {
  final MatchState state;
  MatchStartedEvent(this.state);
}

class TurnStartedEvent extends WsEvent {
  final TurnStartedData data;
  TurnStartedEvent(this.data);
}

class TurnTimerTickEvent extends WsEvent {
  final int timeLeft;
  TurnTimerTickEvent(this.timeLeft);
}

class PlayerMovedEvent extends WsEvent {
  final PlayerMovedData data;
  PlayerMovedEvent(this.data);
}

class ProjectileResultEvent extends WsEvent {
  final ProjectileResult data;
  ProjectileResultEvent(this.data);
}

class PlayerDamagedEvent extends WsEvent {
  final List<DamageEntry> damages;
  PlayerDamagedEvent(this.damages);
}

class SkillUsedEvent extends WsEvent {
  final String playerId;
  final String skillId;
  final int? hp;
  SkillUsedEvent({required this.playerId, required this.skillId, this.hp});
}

class ItemUsedEvent extends WsEvent {
  final String playerId;
  final String itemId;
  final Map<String, BattlePlayerState>? players;
  final WindState? wind;
  ItemUsedEvent({
    required this.playerId,
    required this.itemId,
    this.players,
    this.wind,
  });
}

class MatchEndedEvent extends WsEvent {
  final MatchEndedData data;
  MatchEndedEvent(this.data);
}

class MatchStateSyncEvent extends WsEvent {
  final MatchState state;
  MatchStateSyncEvent(this.state);
}

class WsDisconnectedEvent extends WsEvent {}

class WsReconnectedEvent extends WsEvent {}

WsEvent? parseWsEvent(WsEnvelope envelope) {
  try {
    return switch (envelope.event) {
      'RoomUpdated' => RoomUpdatedEvent(RoomState.fromJson(envelope.data)),
      'RoomError' => RoomErrorEvent(
          code: (envelope.data['error'] as Map)['code'] ?? '',
          message: (envelope.data['error'] as Map)['message'] ?? '',
        ),
      'MatchStarted' => MatchStartedEvent(MatchState.fromJson(envelope.data)),
      'TurnStarted' =>
        TurnStartedEvent(TurnStartedData.fromJson(envelope.data)),
      'TurnTimerTick' =>
        TurnTimerTickEvent(envelope.data['timeLeft'] as int),
      'PlayerMoved' =>
        PlayerMovedEvent(PlayerMovedData.fromJson(envelope.data)),
      'ProjectileResult' =>
        ProjectileResultEvent(ProjectileResult.fromJson(envelope.data)),
      'PlayerDamaged' => PlayerDamagedEvent(
          (envelope.data is List
                  ? envelope.data
                  : [envelope.data])
              .cast<Map<String, dynamic>>()
              .map(DamageEntry.fromJson)
              .toList(),
        ),
      'SkillUsed' => SkillUsedEvent(
          playerId: envelope.data['playerId'] as String,
          skillId: envelope.data['skillId'] as String,
          hp: envelope.data['hp'] as int?,
        ),
      'ItemUsed' => ItemUsedEvent(
          playerId: envelope.data['playerId'] as String,
          itemId: envelope.data['itemId'] as String,
        ),
      'MatchEnded' =>
        MatchEndedEvent(MatchEndedData.fromJson(envelope.data)),
      'MatchStateSync' =>
        MatchStateSyncEvent(MatchState.fromJson(envelope.data)),
      _ => null,
    };
  } catch (_) {
    return null;
  }
}
```

- [ ] **Step 2: Create WebSocket manager**

```dart
// lib/core/ws/ws_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'ws_events.dart';

enum WsConnectionState { disconnected, connecting, connected }

class WsManager {
  final String baseUrl;
  WebSocketChannel? _channel;
  final _eventController = StreamController<WsEvent>.broadcast();
  final _stateController =
      StreamController<WsConnectionState>.broadcast();
  WsConnectionState _state = WsConnectionState.disconnected;
  String? _token;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectDelay = 30;

  WsManager({required this.baseUrl});

  Stream<WsEvent> get eventStream => _eventController.stream;
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  void connect(String token) {
    _token = token;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    if (_state == WsConnectionState.connecting) return;
    _setState(WsConnectionState.connecting);

    try {
      final uri = Uri.parse('$baseUrl/ws?token=$_token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );

      _setState(WsConnectionState.connected);
      if (_reconnectAttempts > 0) {
        _eventController.add(WsReconnectedEvent());
      }
      _reconnectAttempts = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final envelope = WsEnvelope.fromJson(json);
      final event = parseWsEvent(envelope);
      if (event != null) {
        _eventController.add(event);
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _onDisconnected() {
    _setState(WsConnectionState.disconnected);
    _eventController.add(WsDisconnectedEvent());
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_token == null) return;
    _reconnectTimer?.cancel();
    final delay = min(
      pow(2, _reconnectAttempts).toInt(),
      _maxReconnectDelay,
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: delay), _doConnect);
  }

  void send(String event, Map<String, dynamic> data) {
    if (_state != WsConnectionState.connected || _channel == null) return;
    final message = jsonEncode({'event': event, 'data': data});
    _channel!.sink.add(message);
  }

  void disconnect() {
    _token = null;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  void _setState(WsConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
```

- [ ] **Step 3: Write test for event parsing**

```dart
// test/core/ws/ws_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_squad_v1/core/ws/ws_events.dart';

void main() {
  group('WsEnvelope', () {
    test('parses from JSON', () {
      final json = {
        'event': 'TurnTimerTick',
        'data': {'timeLeft': 15},
      };
      final envelope = WsEnvelope.fromJson(json);
      expect(envelope.event, 'TurnTimerTick');
      expect(envelope.data['timeLeft'], 15);
    });

    test('serializes to JSON', () {
      final envelope = WsEnvelope(event: 'Shoot', data: {'angle': 45.0});
      final json = envelope.toJson();
      expect(json['event'], 'Shoot');
      expect((json['data'] as Map)['angle'], 45.0);
    });
  });

  group('parseWsEvent', () {
    test('parses TurnTimerTick', () {
      final envelope = WsEnvelope(
        event: 'TurnTimerTick',
        data: {'timeLeft': 10},
      );
      final event = parseWsEvent(envelope);
      expect(event, isA<TurnTimerTickEvent>());
      expect((event as TurnTimerTickEvent).timeLeft, 10);
    });

    test('parses SkillUsed', () {
      final envelope = WsEnvelope(
        event: 'SkillUsed',
        data: {
          'playerId': 'p1',
          'skillId': 'healing_bloom',
          'hp': 95,
        },
      );
      final event = parseWsEvent(envelope);
      expect(event, isA<SkillUsedEvent>());
      final skill = event as SkillUsedEvent;
      expect(skill.playerId, 'p1');
      expect(skill.skillId, 'healing_bloom');
      expect(skill.hp, 95);
    });

    test('returns null for unknown event', () {
      final envelope = WsEnvelope(event: 'Unknown', data: {});
      expect(parseWsEvent(envelope), isNull);
    });
  });
}
```

- [ ] **Step 4: Run tests and commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter test test/core/ws/
git add lib/core/ws/ test/core/ws/
git commit -m "feat: add WebSocket manager with typed events and auto-reconnect"
```

---

### Task 6: Auth Provider

**Files:**
- Create: `lib/core/auth/auth_provider.dart`
- Create: `lib/core/providers/core_providers.dart`

- [ ] **Step 1: Create core providers**

```dart
// lib/core/providers/core_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_interceptor.dart';
import '../auth/token_storage.dart';
import '../ws/ws_manager.dart';

const _apiBaseUrl = 'http://localhost:8080';
const _wsBaseUrl = 'ws://localhost:8081';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final wsManagerProvider = Provider<WsManager>((ref) {
  final manager = WsManager(baseUrl: _wsBaseUrl);
  ref.onDispose(() => manager.dispose());
  return manager;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final interceptor = AuthInterceptor(
    tokenStorage: tokenStorage,
    baseUrl: _apiBaseUrl,
    onRefreshFailed: () async {
      // Will be handled by auth provider listening to this
      ref.read(tokenStorageProvider).clearAll();
    },
  );

  return ApiClient(
    baseUrl: _apiBaseUrl,
    interceptors: [interceptor],
  );
});
```

- [ ] **Step 2: Create auth provider**

```dart
// lib/core/auth/auth_provider.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../shared/models/auth_models.dart';
import '../api/api_client.dart';
import '../providers/core_providers.dart';
import '../ws/ws_manager.dart';
import 'token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? playerId;
  final String? displayName;
  final bool loading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.playerId,
    this.displayName,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? playerId,
    String? displayName,
    bool? loading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final WsManager _wsManager;

  AuthNotifier({
    required TokenStorage tokenStorage,
    required ApiClient apiClient,
    required WsManager wsManager,
  })  : _tokenStorage = tokenStorage,
        _apiClient = apiClient,
        _wsManager = wsManager,
        super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(loading: true);
    final hasTokens = await _tokenStorage.hasTokens;
    if (!hasTokens) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        loading: false,
      );
      return;
    }

    try {
      // Try to fetch profile to validate token
      final data = await _apiClient.get('/player/profile');
      final playerId = data['playerId'] as String;
      final displayName = data['displayName'] as String;

      // Connect WebSocket
      final token = await _tokenStorage.accessToken;
      if (token != null) {
        _wsManager.connect(token);
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        playerId: playerId,
        displayName: displayName,
        loading: false,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Try refresh
        try {
          await _refreshToken();
          await checkAuth();
        } catch (_) {
          await _tokenStorage.clearAll();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            loading: false,
          );
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          loading: false,
          error: e.message,
        );
      }
    }
  }

  Future<void> guestLogin() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final deviceId = await _getDeviceId();
      final data = await _apiClient.post('/auth/guest-login', data: {
        'deviceInstallId': deviceId,
      });

      final response = LoginResponse.fromJson(data);
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        playerId: response.playerId,
      );

      _wsManager.connect(response.accessToken);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        playerId: response.playerId,
        displayName: response.displayName,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Login failed');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.refreshToken;
      if (refreshToken != null) {
        await _apiClient.post('/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (_) {
      // Ignore logout API errors
    }
    _wsManager.disconnect();
    await _tokenStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _refreshToken() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) throw Exception('No refresh token');

    final data = await _apiClient.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    final response = RefreshResponse.fromJson(data);
    final playerId = await _tokenStorage.playerId;
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      playerId: playerId ?? '',
    );
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.id;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown-ios';
    }
    return 'unknown-device';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    tokenStorage: ref.read(tokenStorageProvider),
    apiClient: ref.read(apiClientProvider),
    wsManager: ref.read(wsManagerProvider),
  );
});
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
git add lib/core/auth/auth_provider.dart lib/core/providers/
git commit -m "feat: add auth provider with guest login, token refresh, WS connect"
```

---

### Task 7: Router & App Shell

**Files:**
- Create: `lib/core/router/app_router.dart`
- Create: `lib/features/auth/splash_screen.dart`
- Create: `lib/features/auth/login_screen.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create router**

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/lobby/lobby_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/mission/mission_screen.dart';
import '../../features/ranking/ranking_screen.dart';
import '../../features/room/room_screen.dart';
import '../../features/match/match_screen.dart';
import '../../features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const LobbyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/shop',
            builder: (_, __) => const ShopScreen(),
          ),
          GoRoute(
            path: '/missions',
            builder: (_, __) => const MissionScreen(),
          ),
          GoRoute(
            path: '/ranking',
            builder: (_, __) => const RankingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/room/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            RoomScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/match',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MatchScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(GoRouterState.of(context).matchedLocation),
        onDestinationSelected: (index) {
          final routes = ['/home', '/profile', '/shop', '/missions', '/ranking'];
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Missions'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Ranking'),
        ],
      ),
    );
  }

  int _calculateIndex(String location) {
    if (location.startsWith('/profile')) return 1;
    if (location.startsWith('/shop')) return 2;
    if (location.startsWith('/missions')) return 3;
    if (location.startsWith('/ranking')) return 4;
    return 0;
  }
}
```

- [ ] **Step 2: Create splash and login screens**

```dart
// lib/features/auth/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BATTLE SQUAD',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BATTLE SQUAD',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Turn-based Artillery PvP',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Play as Guest',
                  loading: auth.loading,
                  onPressed: () {
                    ref.read(authProvider.notifier).guestLogin();
                  },
                  icon: Icons.play_arrow,
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  auth.error!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create placeholder screens for all tabs**

Create stub screens that will be filled in later tasks. Each one is a simple `Scaffold` with a centered text label.

```dart
// lib/features/lobby/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Lobby - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Profile - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/shop/shop_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Shop - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/mission/mission_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Missions - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/ranking/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Ranking - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/room/room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomScreen extends ConsumerWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Room $roomId')),
      body: const Center(child: Text('Room - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/match/match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Match - Coming Soon')),
    );
  }
}
```

```dart
// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Logout',
                color: Colors.red,
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Update main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BattleSquadApp()));
}

class BattleSquadApp extends ConsumerWidget {
  const BattleSquadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Battle Squad',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 5: Verify build and commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/
git commit -m "feat: add GoRouter, auth screens, home shell with bottom nav"
```

---

### Task 8: Lobby — Room List & Create Room

**Files:**
- Create: `lib/features/lobby/lobby_provider.dart`
- Create: `lib/features/lobby/create_room_dialog.dart`
- Modify: `lib/features/lobby/lobby_screen.dart`

- [ ] **Step 1: Create lobby provider**

```dart
// lib/features/lobby/lobby_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/room_models.dart';

class LobbyNotifier extends StateNotifier<AsyncValue<List<RoomListItem>>> {
  final Ref _ref;

  LobbyNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final data = await api.get('/rooms');
      final rooms = (data['rooms'] as List? ?? [])
          .map((r) => RoomListItem.fromJson(r as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final lobbyProvider =
    StateNotifierProvider<LobbyNotifier, AsyncValue<List<RoomListItem>>>((ref) {
  return LobbyNotifier(ref);
});
```

- [ ] **Step 2: Create room dialog**

```dart
// lib/features/lobby/create_room_dialog.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CreateRoomResult {
  final String mode;
  final String mapId;
  final String? password;
  CreateRoomResult({required this.mode, required this.mapId, this.password});
}

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  String _mode = 'pvp_1v1';
  String _mapId = 'grassland_valley';
  final _passwordController = TextEditingController();

  static const _maps = {
    'grassland_valley': 'Grassland Valley',
    'frozen_peak': 'Frozen Peak',
    'steel_base': 'Steel Base',
  };

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Room'),
      backgroundColor: AppColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mode'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'pvp_1v1', label: Text('1v1')),
              ButtonSegment(value: 'pvp_2v2', label: Text('2v2')),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: 16),
          const Text('Map'),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _mapId,
            isExpanded: true,
            items: _maps.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _mapId = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password (optional)',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              CreateRoomResult(
                mode: _mode,
                mapId: _mapId,
                password: _passwordController.text.isEmpty
                    ? null
                    : _passwordController.text,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Implement lobby screen**

```dart
// lib/features/lobby/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ws/ws_events.dart';
import '../../core/ws/ws_manager.dart';
import '../../shared/models/room_models.dart';
import '../../shared/widgets/app_card.dart';
import 'create_room_dialog.dart';
import 'lobby_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(lobbyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Squad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(lobbyProvider.notifier).fetchRooms(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rooms) => RefreshIndicator(
          onRefresh: () => ref.read(lobbyProvider.notifier).fetchRooms(),
          child: rooms.isEmpty
              ? const Center(child: Text('No rooms available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) => _RoomCard(room: rooms[i]),
                ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => _createRoom(context, ref),
            label: const Text('Create Room'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<CreateRoomResult>(
      context: context,
      builder: (_) => const CreateRoomDialog(),
    );
    if (result == null) return;

    final ws = ref.read(wsManagerProvider);
    ws.send('CreateRoom', {
      'mode': result.mode,
      'mapId': result.mapId,
      if (result.password != null) 'password': result.password,
    });

    // Listen for RoomUpdated to navigate
    final sub = ws.eventStream
        .where((e) => e is RoomUpdatedEvent)
        .first
        .then((event) {
      if (context.mounted) {
        final room = (event as RoomUpdatedEvent).room;
        context.push('/room/${room.roomId}');
      }
    });
  }
}

class _RoomCard extends ConsumerWidget {
  final RoomListItem room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () {
        final ws = ref.read(wsManagerProvider);
        ws.send('JoinRoom', {'roomId': room.roomId});

        ws.eventStream
            .where((e) => e is RoomUpdatedEvent || e is RoomErrorEvent)
            .first
            .then((event) {
          if (!context.mounted) return;
          if (event is RoomUpdatedEvent) {
            context.push('/room/${room.roomId}');
          } else if (event is RoomErrorEvent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(event.message)),
            );
          }
        });
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(room.mode == 'pvp_1v1' ? '1v1' : '2v2',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.mapId.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${room.playerCount}/${room.maxPlayers} players',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (room.isLocked)
            const Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/lobby/
git commit -m "feat: add lobby screen with room list, create room dialog"
```

---

### Task 9: Room — Waiting Screen

**Files:**
- Create: `lib/features/room/room_provider.dart`
- Create: `lib/features/room/character_select.dart`
- Create: `lib/features/room/item_select.dart`
- Modify: `lib/features/room/room_screen.dart`

- [ ] **Step 1: Create room provider**

```dart
// lib/features/room/room_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/room_models.dart';

class RoomNotifier extends StateNotifier<RoomState?> {
  final WsManager _ws;
  late final StreamSubscription _sub;

  RoomNotifier(Ref ref)
      : _ws = ref.read(wsManagerProvider),
        super(null) {
    _sub = _ws.eventStream.listen((event) {
      if (event is RoomUpdatedEvent) {
        state = event.room;
      }
    });
  }

  void selectCharacter(String characterId) {
    _ws.send('SelectCharacter', {'characterId': characterId});
  }

  void selectItems(List<String> items) {
    _ws.send('SelectItems', {'items': items});
  }

  void toggleReady() {
    _ws.send('Ready', {});
  }

  void startMatch() {
    _ws.send('StartMatch', {});
  }

  void changeTeam(int teamId) {
    _ws.send('ChangeTeam', {'teamId': teamId});
  }

  void leave() {
    _ws.send('Leave', {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState?>((ref) {
  return RoomNotifier(ref);
});
```

- [ ] **Step 2: Create character select widget**

```dart
// lib/features/room/character_select.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CharacterSelect extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const CharacterSelect({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  static const _characters = [
    {'id': 'rookie', 'name': 'Rookie', 'role': 'Balanced', 'hp': 100, 'dmg': 60, 'def': 50},
    {'id': 'tanko', 'name': 'Tanko', 'role': 'Tank', 'hp': 130, 'dmg': 75, 'def': 80},
    {'id': 'spark', 'name': 'Spark', 'role': 'DPS', 'hp': 90, 'dmg': 55, 'def': 40},
    {'id': 'flora', 'name': 'Flora', 'role': 'Support', 'hp': 95, 'dmg': 45, 'def': 50},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _characters.map((c) {
        final id = c['id'] as String;
        final selected = id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(id),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.characterColor(id).withValues(alpha: 0.3)
                  : AppColors.surface,
              border: Border.all(
                color: selected ? AppTheme.characterColor(id) : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.characterColor(id),
                    )),
                Text(c['role'] as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('HP:${c['hp']} DMG:${c['dmg']} DEF:${c['def']}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 3: Create item select widget**

```dart
// lib/features/room/item_select.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ItemSelect extends StatelessWidget {
  final List<String> availableItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const ItemSelect({
    super.key,
    required this.availableItems,
    required this.selectedItems,
    required this.onChanged,
  });

  static const _itemNames = {
    'medkit': 'Medkit',
    'teleport': 'Teleport',
    'power_shot': 'Power Shot',
    'drill_bomb': 'Drill Bomb',
    'spider_net': 'Spider Net',
    'freeze_bomb': 'Freeze Bomb',
    'air_strike': 'Air Strike',
    'wind_stopper': 'Wind Stopper',
  };

  static const _itemIcons = {
    'medkit': Icons.healing,
    'teleport': Icons.swap_horiz,
    'power_shot': Icons.bolt,
    'drill_bomb': Icons.hardware,
    'spider_net': Icons.grid_on,
    'freeze_bomb': Icons.ac_unit,
    'air_strike': Icons.flight,
    'wind_stopper': Icons.air,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableItems.map((itemId) {
        final selected = selectedItems.contains(itemId);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_itemIcons[itemId] ?? Icons.inventory,
                  size: 16,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_itemNames[itemId] ?? itemId),
            ],
          ),
          selected: selected,
          onSelected: (v) {
            final newList = List<String>.from(selectedItems);
            if (v && newList.length < 3) {
              newList.add(itemId);
            } else {
              newList.remove(itemId);
            }
            onChanged(newList);
          },
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 4: Implement room screen**

```dart
// lib/features/room/room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ws/ws_events.dart';
import '../../core/providers/core_providers.dart';
import '../../shared/widgets/app_button.dart';
import 'character_select.dart';
import 'item_select.dart';
import 'room_provider.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    // Listen for match start
    final ws = ref.read(wsManagerProvider);
    ws.eventStream
        .where((e) => e is MatchStartedEvent)
        .first
        .then((_) {
      if (mounted) context.go('/match');
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    final myId = ref.watch(authProvider).playerId;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final me = room.players.where((p) => p.playerId == myId).firstOrNull;
    final isHost = me?.isHost ?? false;
    final allReady = room.players.where((p) => !p.isHost).every((p) => p.isReady);
    final isFull = room.players.length >= room.maxPlayers;

    return Scaffold(
      appBar: AppBar(
        title: Text('${room.mode == 'pvp_1v1' ? '1v1' : '2v2'} - ${room.mapId.replaceAll('_', ' ')}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(roomProvider.notifier).leave();
            context.go('/home');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player slots
            const Text('Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...room.players.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.teamColor(p.teamId),
                    child: Text(p.displayName[0].toUpperCase()),
                  ),
                  title: Text(p.displayName),
                  subtitle: Text('${p.characterId} • Team ${p.teamId}'),
                  trailing: p.isHost
                      ? const Chip(label: Text('Host'))
                      : p.isReady
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : const Icon(Icons.circle_outlined, color: AppColors.textSecondary),
                )),

            const Divider(height: 32),

            // Character select
            const Text('Select Character', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CharacterSelect(
              selectedId: me?.characterId ?? 'rookie',
              onSelect: (id) {
                ref.read(roomProvider.notifier).selectCharacter(id);
              },
            ),

            const SizedBox(height: 16),

            // Item select
            const Text('Select Items (max 3)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ItemSelect(
              availableItems: const [
                'medkit', 'teleport', 'power_shot', 'drill_bomb',
                'spider_net', 'freeze_bomb', 'air_strike', 'wind_stopper',
              ],
              selectedItems: _selectedItems,
              onChanged: (items) {
                setState(() => _selectedItems = items);
                ref.read(roomProvider.notifier).selectItems(items);
              },
            ),

            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: isHost
                  ? AppButton(
                      label: 'Start Match',
                      onPressed: allReady && isFull
                          ? () => ref.read(roomProvider.notifier).startMatch()
                          : null,
                    )
                  : AppButton(
                      label: me?.isReady == true ? 'Not Ready' : 'Ready',
                      color: me?.isReady == true ? Colors.grey : AppColors.success,
                      onPressed: () => ref.read(roomProvider.notifier).toggleReady(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/room/
git commit -m "feat: add room waiting screen with character/item select"
```

---

### Task 10: Match — Terrain Component

**Files:**
- Create: `lib/features/match/game/terrain_component.dart`
- Test: `test/features/match/terrain_test.dart`

- [ ] **Step 1: Write test for terrain height generation**

```dart
// test/features/match/terrain_test.dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_squad_v1/features/match/game/terrain_component.dart';

void main() {
  group('TerrainData', () {
    test('generates grassland_valley terrain correctly', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'grassland_valley');
      // At x=0: 550 + 100*sin(0) + 40*sin(0) = 550
      expect(terrain.getTerrainHeight(0), closeTo(550, 1));
      // Should have solid below terrain height
      expect(terrain.isSolid(0, 560), true);
      expect(terrain.isSolid(0, 540), false);
    });

    test('generates frozen_peak terrain correctly', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'frozen_peak');
      // At x=0: 500 + 120*sin(0) + 60*cos(0) = 560
      expect(terrain.getTerrainHeight(0), closeTo(560, 1));
    });

    test('generates steel_base terrain correctly', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'steel_base');
      // At x=500 (between 300-600): height = 400
      expect(terrain.getTerrainHeight(500), closeTo(400, 1));
      // At x=0 (outside platforms): height = 600
      expect(terrain.getTerrainHeight(0), closeTo(600, 1));
    });

    test('destroyCircle clears terrain', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'grassland_valley');
      // Destroy circle at (100, 560) - should be inside terrain
      expect(terrain.isSolid(100, 560), true);
      terrain.destroyCircle(100, 560, 20);
      expect(terrain.isSolid(100, 560), false);
    });
  });
}
```

- [ ] **Step 2: Implement TerrainData (logic, separate from Flame)**

```dart
// lib/features/match/game/terrain_component.dart
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TerrainData {
  final int width;
  final int height;
  final String mapId;
  late final Uint8List _mask; // 1 byte per pixel: 0=air, 1=solid

  TerrainData({
    required this.width,
    required this.height,
    required this.mapId,
  }) {
    _mask = Uint8List(width * height);
    _generate();
  }

  double getTerrainHeight(int x) {
    return switch (mapId) {
      'frozen_peak' => 500 + 120 * sin(x * 0.005) + 60 * cos(x * 0.015),
      'steel_base' => (x > 300 && x < 600)
          ? 400
          : (x > 1000 && x < 1300)
              ? 400
              : 600,
      _ => 550 + 100 * sin(x * 0.003) + 40 * sin(x * 0.01), // grassland_valley
    };
  }

  void _generate() {
    for (int x = 0; x < width; x++) {
      final terrainH = getTerrainHeight(x);
      for (int y = 0; y < height; y++) {
        if (y >= terrainH) {
          _mask[y * width + x] = 1;
        }
      }
    }
  }

  bool isSolid(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return _mask[y * width + x] == 1;
  }

  void destroyCircle(double cx, double cy, double radius) {
    final icx = cx.round();
    final icy = cy.round();
    final ir = radius.round();
    for (int y = icy - ir; y <= icy + ir; y++) {
      if (y < 0 || y >= height) continue;
      for (int x = icx - ir; x <= icx + ir; x++) {
        if (x < 0 || x >= width) continue;
        final dx = (x - icx).toDouble();
        final dy = (y - icy).toDouble();
        if (dx * dx + dy * dy <= radius * radius) {
          _mask[y * width + x] = 0;
        }
      }
    }
  }

  bool get isDirty => _needsRepaint;
  bool _needsRepaint = true;
  void markClean() => _needsRepaint = false;
  void markDirty() => _needsRepaint = true;

  Uint8List get mask => _mask;
}

Color _terrainColor(String mapId) {
  return switch (mapId) {
    'frozen_peak' => const Color(0xFFE0E0E0),
    'steel_base' => const Color(0xFF757575),
    _ => const Color(0xFF4CAF50),
  };
}

Color _skyColor(String mapId) {
  return switch (mapId) {
    'frozen_peak' => const Color(0xFF1A237E),
    'steel_base' => const Color(0xFF212121),
    _ => const Color(0xFF1B5E20),
  };
}

class TerrainComponent extends PositionComponent {
  final TerrainData terrainData;
  ui.Image? _cachedImage;

  TerrainComponent({required this.terrainData})
      : super(
          size: Vector2(
            terrainData.width.toDouble(),
            terrainData.height.toDouble(),
          ),
        );

  @override
  Future<void> onLoad() async {
    await _rebuildImage();
  }

  Future<void> _rebuildImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final terrainColor = _terrainColor(terrainData.mapId);
    final skyColor = _skyColor(terrainData.mapId);
    final paint = Paint();

    // Draw sky
    paint.color = skyColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, terrainData.width.toDouble(), terrainData.height.toDouble()),
      paint,
    );

    // Draw terrain pixels
    paint.color = terrainColor;
    for (int x = 0; x < terrainData.width; x++) {
      for (int y = 0; y < terrainData.height; y++) {
        if (terrainData.isSolid(x, y)) {
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
        }
      }
    }

    final picture = recorder.endRecording();
    _cachedImage = await picture.toImage(terrainData.width, terrainData.height);
    terrainData.markClean();
  }

  @override
  void render(Canvas canvas) {
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
  }

  @override
  void update(double dt) {
    if (terrainData.isDirty) {
      _rebuildImage();
    }
  }

  void onTerrainDestroyed(double cx, double cy, double radius) {
    terrainData.destroyCircle(cx, cy, radius);
    terrainData.markDirty();
  }
}
```

- [ ] **Step 3: Run tests and commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter test test/features/match/terrain_test.dart
git add lib/features/match/game/terrain_component.dart test/features/match/
git commit -m "feat: add terrain data generation and rendering component"
```

---

### Task 11: Match — Player, Projectile, Explosion Components

**Files:**
- Create: `lib/features/match/game/player_component.dart`
- Create: `lib/features/match/game/projectile_component.dart`
- Create: `lib/features/match/game/explosion_component.dart`

- [ ] **Step 1: Create player component**

```dart
// lib/features/match/game/player_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PlayerComponent extends PositionComponent {
  final String playerId;
  final String displayName;
  final String characterId;
  final int teamId;
  int hp;
  int maxHp;
  bool isAlive;

  PlayerComponent({
    required this.playerId,
    required this.displayName,
    required this.characterId,
    required this.teamId,
    required this.hp,
    required this.maxHp,
    required Vector2 position,
    this.isAlive = true,
  }) : super(
          position: position,
          size: Vector2(32, 48),
          anchor: Anchor.bottomCenter,
        );

  Color get color => AppTheme.characterColor(characterId);

  @override
  void render(Canvas canvas) {
    if (!isAlive) return;

    // Body (colored rectangle)
    final bodyPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 8, size.x, size.y - 8),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Name label
    final textPainter = TextPainter(
      text: TextSpan(
        text: displayName.length > 6
            ? '${displayName.substring(0, 6)}..'
            : displayName,
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((size.x - textPainter.width) / 2, -2));

    // HP bar
    final hpRatio = hp / maxHp;
    final barWidth = size.x;
    final barBg = Paint()..color = Colors.red.shade900;
    final barFg = Paint()
      ..color = hpRatio > 0.5
          ? Colors.green
          : hpRatio > 0.25
              ? Colors.orange
              : Colors.red;
    canvas.drawRect(Rect.fromLTWH(0, size.y + 2, barWidth, 4), barBg);
    canvas.drawRect(Rect.fromLTWH(0, size.y + 2, barWidth * hpRatio, 4), barFg);
  }

  void updateFromState({required int newHp, required bool alive, Vector2? newPos}) {
    hp = newHp;
    isAlive = alive;
    if (newPos != null) position = newPos;
  }
}
```

- [ ] **Step 2: Create projectile component**

```dart
// lib/features/match/game/projectile_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/match_models.dart';

class ProjectileComponent extends PositionComponent {
  final List<ProjectileStep> path;
  final VoidCallback onComplete;
  double _elapsed = 0;
  int _currentIndex = 0;
  bool _completed = false;

  ProjectileComponent({
    required this.path,
    required this.onComplete,
  }) : super(
          size: Vector2(8, 8),
          anchor: Anchor.center,
        ) {
    if (path.isNotEmpty) {
      position = Vector2(path[0].position.x, path[0].position.y);
    }
  }

  @override
  void update(double dt) {
    if (_completed || path.isEmpty) return;

    _elapsed += dt;

    // Find the path segment we're in
    while (_currentIndex < path.length - 1 &&
        _elapsed >= path[_currentIndex + 1].time) {
      _currentIndex++;
    }

    if (_currentIndex >= path.length - 1) {
      position = Vector2(
        path.last.position.x,
        path.last.position.y,
      );
      _completed = true;
      onComplete();
      return;
    }

    // Interpolate between current and next point
    final current = path[_currentIndex];
    final next = path[_currentIndex + 1];
    final segmentDuration = next.time - current.time;
    final segmentElapsed = _elapsed - current.time;
    final t = segmentDuration > 0 ? (segmentElapsed / segmentDuration).clamp(0.0, 1.0) : 1.0;

    position = Vector2(
      current.position.x + (next.position.x - current.position.x) * t,
      current.position.y + (next.position.y - current.position.y) * t,
    );
  }

  @override
  void render(Canvas canvas) {
    if (_completed) return;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, paint);

    // Trail
    final trailPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, trailPaint);
  }
}
```

- [ ] **Step 3: Create explosion component**

```dart
// lib/features/match/game/explosion_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ExplosionComponent extends PositionComponent {
  final double radius;
  final VoidCallback onComplete;
  double _elapsed = 0;
  static const _duration = 0.5; // 500ms animation

  ExplosionComponent({
    required Vector2 center,
    required this.radius,
    required this.onComplete,
  }) : super(
          position: center,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      onComplete();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final currentRadius = radius * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Outer ring
    final outerPaint = Paint()
      ..color = Colors.orange.withValues(alpha: alpha * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      currentRadius,
      outerPaint,
    );

    // Inner core
    final innerPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      currentRadius * 0.5,
      innerPaint,
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/match/game/
git commit -m "feat: add player, projectile, and explosion Flame components"
```

---

### Task 12: Match — BattleGame & Match Provider

**Files:**
- Create: `lib/features/match/game/battle_game.dart`
- Create: `lib/features/match/match_provider.dart`

- [ ] **Step 1: Create match provider**

```dart
// lib/features/match/match_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/match_models.dart';

class MatchData {
  final MatchState state;
  final ProjectileResult? lastProjectile;
  final List<DamageEntry>? lastDamages;
  final int turnTimeLeft;
  final MatchEndedData? endedData;

  MatchData({
    required this.state,
    this.lastProjectile,
    this.lastDamages,
    this.turnTimeLeft = 20,
    this.endedData,
  });

  MatchData copyWith({
    MatchState? state,
    ProjectileResult? lastProjectile,
    List<DamageEntry>? lastDamages,
    int? turnTimeLeft,
    MatchEndedData? endedData,
  }) {
    return MatchData(
      state: state ?? this.state,
      lastProjectile: lastProjectile,
      lastDamages: lastDamages,
      turnTimeLeft: turnTimeLeft ?? this.turnTimeLeft,
      endedData: endedData ?? this.endedData,
    );
  }
}

class MatchNotifier extends StateNotifier<MatchData?> {
  final WsManager _ws;
  late final StreamSubscription _sub;

  MatchNotifier(Ref ref)
      : _ws = ref.read(wsManagerProvider),
        super(null) {
    _sub = _ws.eventStream.listen(_handleEvent);
  }

  void _handleEvent(WsEvent event) {
    switch (event) {
      case MatchStartedEvent(:final state):
        this.state = MatchData(state: state);
      case MatchStateSyncEvent(:final state):
        this.state = MatchData(state: state);
      case TurnStartedEvent(:final data):
        if (state == null) return;
        final players = Map<String, BattlePlayerState>.from(state!.state.players);
        // Update move energy for current player
        if (players.containsKey(data.currentPlayerId)) {
          final p = players[data.currentPlayerId]!;
          players[data.currentPlayerId] = BattlePlayerState(
            playerId: p.playerId, displayName: p.displayName, teamId: p.teamId,
            characterId: p.characterId, hp: p.hp, maxHp: p.maxHp, defense: p.defense,
            position: p.position, moveEnergy: data.moveEnergy, items: p.items,
            statusEffects: p.statusEffects, isAlive: p.isAlive, isBot: p.isBot,
            skillCooldown: p.skillCooldown, damageDealt: p.damageDealt,
            killCount: p.killCount, shotsFired: p.shotsFired, shotsHit: p.shotsHit,
          );
        }
        final newState = MatchState(
          matchId: state!.state.matchId, roomId: state!.state.roomId,
          mode: state!.state.mode, mapId: state!.state.mapId,
          turnIndex: data.turnIndex, currentPlayerId: data.currentPlayerId,
          wind: data.wind, players: players, status: state!.state.status,
          turnOrder: state!.state.turnOrder, turnTimeLeft: 20,
          activeEffects: state!.state.activeEffects,
        );
        this.state = MatchData(state: newState, turnTimeLeft: 20);
      case TurnTimerTickEvent(:final timeLeft):
        if (state != null) {
          this.state = state!.copyWith(turnTimeLeft: timeLeft);
        }
      case ProjectileResultEvent(:final data):
        if (state != null) {
          this.state = state!.copyWith(lastProjectile: data);
        }
      case PlayerDamagedEvent(:final damages):
        if (state == null) return;
        final players = Map<String, BattlePlayerState>.from(state!.state.players);
        for (final d in damages) {
          if (players.containsKey(d.playerId)) {
            final p = players[d.playerId]!;
            players[d.playerId] = BattlePlayerState(
              playerId: p.playerId, displayName: p.displayName, teamId: p.teamId,
              characterId: p.characterId, hp: d.hp, maxHp: p.maxHp, defense: p.defense,
              position: p.position, moveEnergy: p.moveEnergy, items: p.items,
              statusEffects: p.statusEffects, isAlive: d.isAlive, isBot: p.isBot,
              skillCooldown: p.skillCooldown, damageDealt: p.damageDealt,
              killCount: p.killCount, shotsFired: p.shotsFired, shotsHit: p.shotsHit,
            );
          }
        }
        final newState = MatchState(
          matchId: state!.state.matchId, roomId: state!.state.roomId,
          mode: state!.state.mode, mapId: state!.state.mapId,
          turnIndex: state!.state.turnIndex,
          currentPlayerId: state!.state.currentPlayerId,
          wind: state!.state.wind, players: players, status: state!.state.status,
          turnOrder: state!.state.turnOrder, turnTimeLeft: state!.state.turnTimeLeft,
          activeEffects: state!.state.activeEffects,
        );
        this.state = state!.copyWith(state: newState, lastDamages: damages);
      case PlayerMovedEvent(:final data):
        if (state == null) return;
        final players = Map<String, BattlePlayerState>.from(state!.state.players);
        if (players.containsKey(data.playerId)) {
          final p = players[data.playerId]!;
          players[data.playerId] = BattlePlayerState(
            playerId: p.playerId, displayName: p.displayName, teamId: p.teamId,
            characterId: p.characterId, hp: p.hp, maxHp: p.maxHp, defense: p.defense,
            position: data.position, moveEnergy: data.moveEnergy, items: p.items,
            statusEffects: p.statusEffects, isAlive: p.isAlive, isBot: p.isBot,
            skillCooldown: p.skillCooldown, damageDealt: p.damageDealt,
            killCount: p.killCount, shotsFired: p.shotsFired, shotsHit: p.shotsHit,
          );
        }
        final newState = MatchState(
          matchId: state!.state.matchId, roomId: state!.state.roomId,
          mode: state!.state.mode, mapId: state!.state.mapId,
          turnIndex: state!.state.turnIndex,
          currentPlayerId: state!.state.currentPlayerId,
          wind: state!.state.wind, players: players, status: state!.state.status,
          turnOrder: state!.state.turnOrder, turnTimeLeft: state!.state.turnTimeLeft,
          activeEffects: state!.state.activeEffects,
        );
        this.state = state!.copyWith(state: newState);
      case MatchEndedEvent(:final data):
        if (state != null) {
          this.state = state!.copyWith(endedData: data);
        }
      default:
        break;
    }
  }

  void shoot({
    required double angle,
    required double power,
    String actionMode = 'weapon',
    String? itemId,
    double? targetX,
  }) {
    _ws.send('Shoot', {
      'angle': angle,
      'power': power,
      'actionMode': actionMode,
      if (itemId != null) 'itemId': itemId,
      if (targetX != null) 'targetX': targetX,
      'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void move(String direction, double targetX) {
    _ws.send('Move', {
      'direction': direction,
      'targetX': targetX,
      'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void useItem(String itemId, {Vector2Model? targetPosition}) {
    _ws.send('UseItem', {
      'itemId': itemId,
      if (targetPosition != null)
        'targetPosition': {'x': targetPosition.x, 'y': targetPosition.y},
      'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void endTurn() {
    _ws.send('EndTurn', {});
  }

  void reconnect() {
    _ws.send('Reconnect', {});
  }

  void leave() {
    _ws.send('Leave', {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final matchProvider = StateNotifierProvider<MatchNotifier, MatchData?>((ref) {
  return MatchNotifier(ref);
});
```

- [ ] **Step 2: Create BattleGame**

```dart
// lib/features/match/game/battle_game.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/match_models.dart';
import 'terrain_component.dart';
import 'player_component.dart';
import 'projectile_component.dart';
import 'explosion_component.dart';

class BattleGame extends FlameGame {
  final String mapId;
  final Map<String, BattlePlayerState> initialPlayers;

  late TerrainComponent terrainComp;
  final Map<String, PlayerComponent> playerComponents = {};

  BattleGame({
    required this.mapId,
    required this.initialPlayers,
  });

  @override
  Future<void> onLoad() async {
    // Set up camera
    camera.viewfinder.visibleGameSize = Vector2(1600, 900);
    camera.viewfinder.position = Vector2(800, 450);
    camera.viewfinder.anchor = Anchor.center;

    // Add terrain
    final terrainData = TerrainData(width: 1600, height: 900, mapId: mapId);
    terrainComp = TerrainComponent(terrainData: terrainData);
    world.add(terrainComp);

    // Add players
    for (final entry in initialPlayers.entries) {
      final p = entry.value;
      final comp = PlayerComponent(
        playerId: p.playerId,
        displayName: p.displayName,
        characterId: p.characterId,
        teamId: p.teamId,
        hp: p.hp,
        maxHp: p.maxHp,
        position: Vector2(p.position.x, p.position.y),
      );
      playerComponents[p.playerId] = comp;
      world.add(comp);
    }
  }

  void updatePlayer(String playerId, {int? hp, bool? isAlive, Vector2? position}) {
    final comp = playerComponents[playerId];
    if (comp == null) return;
    comp.updateFromState(
      newHp: hp ?? comp.hp,
      alive: isAlive ?? comp.isAlive,
      newPos: position,
    );
  }

  void animateProjectile(ProjectileResult result, VoidCallback onDone) {
    if (result.path.isEmpty) {
      onDone();
      return;
    }

    final projectile = ProjectileComponent(
      path: result.path,
      onComplete: () {
        // Show explosion
        if (result.explosionPoint != null) {
          final explosion = ExplosionComponent(
            center: Vector2(
              result.explosionPoint!.x,
              result.explosionPoint!.y,
            ),
            radius: result.explosionRadius,
            onComplete: () {},
          );
          world.add(explosion);

          // Destroy terrain
          if (result.terrainDestroyed) {
            terrainComp.onTerrainDestroyed(
              result.explosionPoint!.x,
              result.explosionPoint!.y,
              result.explosionRadius,
            );
          }
        }
        onDone();
      },
    );
    world.add(projectile);
  }

  void followTarget(Vector2 target) {
    camera.viewfinder.position = target;
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/match/
git commit -m "feat: add BattleGame, match provider with full WS event handling"
```

---

### Task 13: Match — HUD Overlay & Controls

**Files:**
- Create: `lib/features/match/hud/match_hud.dart`
- Create: `lib/features/match/hud/angle_power_control.dart`
- Create: `lib/features/match/hud/item_skill_bar.dart`
- Create: `lib/features/match/hud/wind_indicator.dart`

- [ ] **Step 1: Create wind indicator**

```dart
// lib/features/match/hud/wind_indicator.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class WindIndicator extends StatelessWidget {
  final int direction; // -1, 0, 1
  final int power; // 0-4

  const WindIndicator({
    super.key,
    required this.direction,
    required this.power,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = direction == 0
        ? '-'
        : direction < 0
            ? '←'
            : '→';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.air, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$arrow $power',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create angle/power control**

```dart
// lib/features/match/hud/angle_power_control.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AnglePowerControl extends StatelessWidget {
  final double angle;
  final double power;
  final bool enabled;
  final ValueChanged<double> onAngleChanged;
  final ValueChanged<double> onPowerChanged;
  final VoidCallback onShoot;

  const AnglePowerControl({
    super.key,
    required this.angle,
    required this.power,
    required this.enabled,
    required this.onAngleChanged,
    required this.onPowerChanged,
    required this.onShoot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Angle slider
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Angle')),
              Expanded(
                child: Slider(
                  value: angle,
                  min: 0,
                  max: 180,
                  divisions: 180,
                  label: '${angle.round()}°',
                  onChanged: enabled ? onAngleChanged : null,
                ),
              ),
              SizedBox(width: 40, child: Text('${angle.round()}°')),
            ],
          ),
          // Power slider
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Power')),
              Expanded(
                child: Slider(
                  value: power,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${power.round()}',
                  activeColor: AppColors.accent,
                  onChanged: enabled ? onPowerChanged : null,
                ),
              ),
              SizedBox(width: 40, child: Text('${power.round()}')),
            ],
          ),
          const SizedBox(height: 8),
          // Shoot button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: enabled ? onShoot : null,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('SHOOT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create item/skill bar**

```dart
// lib/features/match/hud/item_skill_bar.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ItemSkillBar extends StatelessWidget {
  final List<String> items;
  final int skillCooldown;
  final String? activeItemId;
  final String actionMode; // weapon, skill, item
  final bool enabled;
  final ValueChanged<String> onItemSelected;
  final VoidCallback onSkillSelected;
  final VoidCallback onWeaponSelected;

  const ItemSkillBar({
    super.key,
    required this.items,
    required this.skillCooldown,
    required this.activeItemId,
    required this.actionMode,
    required this.enabled,
    required this.onItemSelected,
    required this.onSkillSelected,
    required this.onWeaponSelected,
  });

  static const _itemIcons = {
    'medkit': Icons.healing,
    'teleport': Icons.swap_horiz,
    'power_shot': Icons.bolt,
    'drill_bomb': Icons.hardware,
    'spider_net': Icons.grid_on,
    'freeze_bomb': Icons.ac_unit,
    'air_strike': Icons.flight,
    'wind_stopper': Icons.air,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Weapon button
          _ActionButton(
            icon: Icons.gps_fixed,
            label: 'Weapon',
            isActive: actionMode == 'weapon',
            enabled: enabled,
            onTap: onWeaponSelected,
          ),
          const SizedBox(width: 8),
          // Skill button
          _ActionButton(
            icon: Icons.auto_awesome,
            label: skillCooldown > 0 ? 'CD:$skillCooldown' : 'Skill',
            isActive: actionMode == 'skill',
            enabled: enabled && skillCooldown == 0,
            onTap: onSkillSelected,
          ),
          const SizedBox(width: 8),
          // Item buttons
          ...items.map((itemId) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ActionButton(
                  icon: _itemIcons[itemId] ?? Icons.inventory,
                  label: itemId.replaceAll('_', '\n'),
                  isActive: actionMode == 'item' && activeItemId == itemId,
                  enabled: enabled,
                  onTap: () => onItemSelected(itemId),
                ),
              )),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
            Text(label,
                style: TextStyle(
                  fontSize: 7,
                  color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create match HUD (combines all)**

```dart
// lib/features/match/hud/match_hud.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../match_provider.dart';
import 'angle_power_control.dart';
import 'item_skill_bar.dart';
import 'wind_indicator.dart';

class MatchHud extends ConsumerStatefulWidget {
  final void Function(double angle, double power, String actionMode, String? itemId) onShoot;
  final void Function(String direction, double targetX) onMove;
  final VoidCallback onEndTurn;

  const MatchHud({
    super.key,
    required this.onShoot,
    required this.onMove,
    required this.onEndTurn,
  });

  @override
  ConsumerState<MatchHud> createState() => _MatchHudState();
}

class _MatchHudState extends ConsumerState<MatchHud> {
  double _angle = 45;
  double _power = 50;
  String _actionMode = 'weapon';
  String? _activeItemId;

  @override
  Widget build(BuildContext context) {
    final matchData = ref.watch(matchProvider);
    if (matchData == null) return const SizedBox.shrink();

    final myId = ref.watch(authProvider).playerId;
    final state = matchData.state;
    final isMyTurn = state.currentPlayerId == myId;
    final me = state.players[myId];

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Turn indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMyTurn ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isMyTurn ? 'YOUR TURN' : 'Waiting...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: matchData.turnTimeLeft <= 5
                        ? AppColors.error
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${matchData.turnTimeLeft}s',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Wind
                WindIndicator(
                  direction: state.wind.direction,
                  power: state.wind.power,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Item/Skill bar
          if (isMyTurn && me != null)
            ItemSkillBar(
              items: me.items,
              skillCooldown: me.skillCooldown,
              activeItemId: _activeItemId,
              actionMode: _actionMode,
              enabled: isMyTurn,
              onWeaponSelected: () => setState(() {
                _actionMode = 'weapon';
                _activeItemId = null;
              }),
              onSkillSelected: () => setState(() {
                _actionMode = 'skill';
                _activeItemId = null;
              }),
              onItemSelected: (itemId) => setState(() {
                _actionMode = 'item';
                _activeItemId = itemId;
              }),
            ),

          // Angle/Power controls
          AnglePowerControl(
            angle: _angle,
            power: _power,
            enabled: isMyTurn,
            onAngleChanged: (v) => setState(() => _angle = v),
            onPowerChanged: (v) => setState(() => _power = v),
            onShoot: () {
              widget.onShoot(_angle, _power, _actionMode, _activeItemId);
              // Reset to weapon after using item/skill
              setState(() {
                _actionMode = 'weapon';
                _activeItemId = null;
              });
            },
          ),

          // Move + End Turn buttons
          if (isMyTurn)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onMove('left', -30),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Move Left'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onEndTurn,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('End Turn'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onMove('right', 30),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Move Right'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/match/hud/
git commit -m "feat: add match HUD with angle/power controls, item/skill bar, wind indicator"
```

---

### Task 14: Match — Screen Integration & Result Dialog

**Files:**
- Create: `lib/features/match/match_result_dialog.dart`
- Modify: `lib/features/match/match_screen.dart`

- [ ] **Step 1: Create match result dialog**

```dart
// lib/features/match/match_result_dialog.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/match_models.dart';

class MatchResultDialog extends StatelessWidget {
  final MatchEndedData endedData;
  final String myPlayerId;
  final Map<String, BattlePlayerState> players;
  final VoidCallback onBackToLobby;

  const MatchResultDialog({
    super.key,
    required this.endedData,
    required this.myPlayerId,
    required this.players,
    required this.onBackToLobby,
  });

  @override
  Widget build(BuildContext context) {
    final me = players[myPlayerId];
    final myTeam = me?.teamId ?? 0;
    final isWin = endedData.winningTeam == myTeam;
    final isDraw = endedData.winningTeam == 0;
    final isNoContest = endedData.result == 'no_contest';

    final resultText = isNoContest
        ? 'NO CONTEST'
        : isDraw
            ? 'DRAW'
            : isWin
                ? 'VICTORY!'
                : 'DEFEAT';

    final resultColor = isNoContest || isDraw
        ? AppColors.warning
        : isWin
            ? AppColors.success
            : AppColors.error;

    final reward = endedData.rewards?[myPlayerId];

    return Dialog(
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultText,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            if (isNoContest && endedData.message != null) ...[
              const SizedBox(height: 8),
              Text(endedData.message!,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 24),
            if (reward != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(icon: Icons.star, label: 'EXP', value: '+${reward.exp}'),
                  _StatItem(icon: Icons.monetization_on, label: 'Coins', value: '+${reward.coins}',
                      color: AppColors.coin),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (me != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: 'Damage', value: '${me.damageDealt}'),
                  _StatItem(label: 'Kills', value: '${me.killCount}'),
                  _StatItem(
                    label: 'Accuracy',
                    value: me.shotsFired > 0
                        ? '${(me.shotsHit / me.shotsFired * 100).round()}%'
                        : '-',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackToLobby,
                child: const Text('Back to Lobby'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? color;

  const _StatItem({this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            )),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
```

- [ ] **Step 2: Implement match screen**

```dart
// lib/features/match/match_screen.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import 'game/battle_game.dart';
import 'hud/match_hud.dart';
import 'match_provider.dart';
import 'match_result_dialog.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  BattleGame? _game;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    final matchData = ref.watch(matchProvider);

    if (matchData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Initialize game once
    _game ??= BattleGame(
      mapId: matchData.state.mapId,
      initialPlayers: matchData.state.players,
    );

    // Handle projectile animation
    final projectile = matchData.lastProjectile;
    if (projectile != null && _game != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game!.animateProjectile(projectile, () {});
      });
    }

    // Update player positions/HP
    for (final entry in matchData.state.players.entries) {
      final p = entry.value;
      _game?.updatePlayer(
        p.playerId,
        hp: p.hp,
        isAlive: p.isAlive,
        position: Vector2(p.position.x, p.position.y),
      );
    }

    // Show result dialog
    if (matchData.endedData != null && !_showResult) {
      _showResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => MatchResultDialog(
            endedData: matchData.endedData!,
            myPlayerId: ref.read(authProvider).playerId ?? '',
            players: matchData.state.players,
            onBackToLobby: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flame game
          GameWidget(game: _game!),
          // HUD overlay
          MatchHud(
            onShoot: (angle, power, mode, itemId) {
              ref.read(matchProvider.notifier).shoot(
                    angle: angle,
                    power: power,
                    actionMode: mode,
                    itemId: itemId,
                  );
            },
            onMove: (direction, delta) {
              final myId = ref.read(authProvider).playerId;
              final me = matchData.state.players[myId];
              if (me == null) return;
              final targetX = me.position.x + (direction == 'right' ? delta : -delta);
              ref.read(matchProvider.notifier).move(direction, targetX);
            },
            onEndTurn: () {
              ref.read(matchProvider.notifier).endTurn();
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/match/
git commit -m "feat: integrate match screen with Flame game, HUD, and result dialog"
```

---

### Task 15: Profile Screen

**Files:**
- Create: `lib/features/profile/profile_provider.dart`
- Create: `lib/features/profile/inventory_grid.dart`
- Create: `lib/features/profile/match_history_list.dart`
- Modify: `lib/features/profile/profile_screen.dart`

- [ ] **Step 1: Create profile provider**

```dart
// lib/features/profile/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/player_models.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<PlayerProfile>> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final data = await api.get('/player/profile');
      state = AsyncValue.data(PlayerProfile.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      final api = _ref.read(apiClientProvider);
      final data = await api.put('/player/profile', data: {'displayName': name});
      state = AsyncValue.data(PlayerProfile.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<PlayerProfile>>((ref) {
  return ProfileNotifier(ref);
});

final inventoryProvider =
    FutureProvider<List<InventoryItem>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/player/inventory');
  return (data['items'] as List? ?? [])
      .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

final matchHistoryProvider =
    FutureProvider.family<List<MatchHistoryEntry>, int>((ref, page) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/player/match-history', queryParams: {
    'page': page,
    'limit': 20,
  });
  return (data['entries'] as List? ?? [])
      .map((e) => MatchHistoryEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});
```

- [ ] **Step 2: Create inventory grid and match history list**

```dart
// lib/features/profile/inventory_grid.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/player_models.dart';

class InventoryGrid extends StatelessWidget {
  final List<InventoryItem> items;
  const InventoryGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet'));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory, color: AppColors.textSecondary),
              Text(item.itemId, style: const TextStyle(fontSize: 10)),
              Text('x${item.quantity}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
```

```dart
// lib/features/profile/match_history_list.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/player_models.dart';

class MatchHistoryList extends StatelessWidget {
  final List<MatchHistoryEntry> entries;
  const MatchHistoryList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No matches yet'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final resultColor = switch (e.result) {
          'win' => AppColors.success,
          'loss' => AppColors.error,
          _ => AppColors.warning,
        };
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: resultColor,
            child: Text(e.result[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text('${e.mode.toUpperCase()} - ${e.mapId.replaceAll('_', ' ')}'),
          subtitle: Text('+${e.expGained} EXP  +${e.coinGained} Coins'),
          trailing: Text(e.playedAt.substring(0, 10),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Implement profile screen**

```dart
// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/currency_display.dart';
import 'inventory_grid.dart';
import 'match_history_list.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final historyAsync = ref.watch(matchHistoryProvider(1));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _editName(context, ref, profile.displayName),
                          child: Row(
                            children: [
                              Text(profile.displayName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                        Text('Level ${profile.level}',
                            style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: profile.exp / 1000, // simplified
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CurrencyDisplay(coins: profile.coin, gems: profile.gem),

              const Divider(height: 32),

              // Inventory
              const Text('Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              inventoryAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (items) => InventoryGrid(items: items),
              ),

              const Divider(height: 32),

              // Match History
              const Text('Match History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (entries) => MatchHistoryList(entries: entries),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editName(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateDisplayName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/profile/
git commit -m "feat: add profile screen with inventory grid and match history"
```

---

### Task 16: Shop Screen

**Files:**
- Create: `lib/features/shop/shop_provider.dart`
- Modify: `lib/features/shop/shop_screen.dart`

- [ ] **Step 1: Create shop provider**

```dart
// lib/features/shop/shop_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/core_providers.dart';
import '../../shared/models/shop_models.dart';

final shopOffersProvider = FutureProvider<List<ShopOffer>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/shop/offers');
  return (data['offers'] as List? ?? [])
      .map((e) => ShopOffer.fromJson(e as Map<String, dynamic>))
      .toList();
});

final shopPurchaseProvider = Provider<ShopPurchaseService>((ref) {
  return ShopPurchaseService(ref.read(apiClientProvider));
});

class ShopPurchaseService {
  final ApiClient _api;
  const ShopPurchaseService(this._api);

  Future<PurchaseResponse> purchase(String offerId) async {
    final key = const Uuid().v4();
    final data = await _api.post('/shop/purchase', data: {
      'offerId': offerId,
      'idempotencyKey': key,
    });
    return PurchaseResponse.fromJson(data);
  }
}
```

- [ ] **Step 2: Implement shop screen**

```dart
// lib/features/shop/shop_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'shop_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(shopOffersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (offers) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (_, i) {
            final offer = offers[i];
            final currencyIcon = offer.priceCurrency == 'coin'
                ? Icons.monetization_on
                : Icons.diamond;
            final currencyColor =
                offer.priceCurrency == 'coin' ? AppColors.coin : AppColors.gem;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.inventory, size: 40),
                title: Text(offer.itemId.replaceAll('_', ' ').toUpperCase()),
                subtitle: Text('${offer.offerType} • x${offer.quantity}'),
                trailing: TextButton.icon(
                  icon: Icon(currencyIcon, color: currencyColor, size: 18),
                  label: Text('${offer.priceAmount}',
                      style: TextStyle(color: currencyColor)),
                  onPressed: () => _confirmPurchase(context, ref, offer),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, WidgetRef ref, offer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text(
          'Buy ${offer.itemId.replaceAll('_', ' ')} for ${offer.priceAmount} ${offer.priceCurrency}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(shopPurchaseProvider).purchase(offer.offerId);
                if (context.mounted) {
                  showSuccessSnackbar(context, 'Purchase successful!');
                  ref.invalidate(shopOffersProvider);
                }
              } catch (e) {
                if (context.mounted) showErrorSnackbar(context, '$e');
              }
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/shop/
git commit -m "feat: add shop screen with offers list and purchase flow"
```

---

### Task 17: Mission Screen

**Files:**
- Create: `lib/features/mission/mission_provider.dart`
- Modify: `lib/features/mission/mission_screen.dart`

- [ ] **Step 1: Create mission provider**

```dart
// lib/features/mission/mission_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/mission_models.dart';

final dailyMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/missions/daily');
  return (data['missions'] as List? ?? [])
      .map((e) => Mission.fromJson(e as Map<String, dynamic>))
      .toList();
});

final achievementsProvider = FutureProvider<List<Mission>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/missions/achievements');
  return (data['missions'] as List? ?? [])
      .map((e) => Mission.fromJson(e as Map<String, dynamic>))
      .toList();
});

Future<ClaimResponse> claimMission(Ref ref, String missionId) async {
  final api = ref.read(apiClientProvider);
  final data = await api.post('/missions/claim', data: {'missionId': missionId});
  return ClaimResponse.fromJson(data);
}
```

- [ ] **Step 2: Implement mission screen**

```dart
// lib/features/mission/mission_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/mission_models.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'mission_provider.dart';

class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MissionList(provider: dailyMissionsProvider),
            _MissionList(provider: achievementsProvider),
          ],
        ),
      ),
    );
  }
}

class _MissionList extends ConsumerWidget {
  final FutureProvider<List<Mission>> provider;
  const _MissionList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(provider);

    return missionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (missions) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: missions.length,
        itemBuilder: (_, i) {
          final m = missions[i];
          final progress = m.requiredValue > 0
              ? (m.currentValue / m.requiredValue).clamp(0.0, 1.0)
              : 0.0;
          final canClaim = m.currentValue >= m.requiredValue && !m.isClaimed;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.target.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surface,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${m.currentValue}/${m.requiredValue}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Row(
                        children: [
                          if (m.rewardCoin > 0) ...[
                            const Icon(Icons.monetization_on,
                                size: 14, color: AppColors.coin),
                            Text(' ${m.rewardCoin}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                          ],
                          if (m.rewardGem > 0) ...[
                            const Icon(Icons.diamond, size: 14, color: AppColors.gem),
                            Text(' ${m.rewardGem}', style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (canClaim) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await claimMission(ref, m.missionId);
                            ref.invalidate(provider);
                            if (context.mounted) {
                              showSuccessSnackbar(context, 'Reward claimed!');
                            }
                          } catch (e) {
                            if (context.mounted) showErrorSnackbar(context, '$e');
                          }
                        },
                        child: const Text('Claim'),
                      ),
                    ),
                  ],
                  if (m.isClaimed)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Claimed',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/mission/
git commit -m "feat: add mission screen with daily/achievements tabs and claim flow"
```

---

### Task 18: Ranking Screen

**Files:**
- Create: `lib/features/ranking/ranking_provider.dart`
- Modify: `lib/features/ranking/ranking_screen.dart`

- [ ] **Step 1: Create ranking provider**

```dart
// lib/features/ranking/ranking_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../shared/models/rank_models.dart';

final myRankProvider = FutureProvider<PlayerRank>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/rank/me');
  return PlayerRank.fromJson(data);
});

final leaderboardProvider =
    FutureProvider.family<List<PlayerRank>, int>((ref, page) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/rank/leaderboard', queryParams: {
    'page': page,
    'limit': 50,
  });
  return (data['leaderboard'] as List? ?? [])
      .map((e) => PlayerRank.fromJson(e as Map<String, dynamic>))
      .toList();
});

final currentSeasonProvider = FutureProvider<Season>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/rank/seasons/current');
  return Season.fromJson(data);
});
```

- [ ] **Step 2: Implement ranking screen**

```dart
// lib/features/ranking/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'ranking_provider.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRankAsync = ref.watch(myRankProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(1));
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Season info
            seasonAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (season) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(season.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Ends: ${season.endsAt.substring(0, 10)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // My rank
            myRankAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (rank) => Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${rank.tier.toUpperCase()} ${rank.division}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Rating: ${rank.rating}',
                              style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text('${rank.wins}W ${rank.losses}L ${rank.draws}D',
                              style: const TextStyle(fontSize: 14)),
                          if (rank.winStreak > 0)
                            Text('${rank.winStreak} streak',
                                style: const TextStyle(
                                    color: AppColors.success, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Leaderboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Leaderboard
            leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (players) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: players.length,
                itemBuilder: (_, i) {
                  final p = players[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: i < 3 ? AppColors.coin : AppColors.surface,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(p.displayName),
                    subtitle: Text('${p.tier} ${p.division}'),
                    trailing: Text('${p.rating}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/ranking/
git commit -m "feat: add ranking screen with my rank, season info, and leaderboard"
```

---

### Task 19: Settings Screen (Full)

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Implement full settings screen**

```dart
// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_snackbar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound toggle
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Coming soon'),
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),

          const Divider(height: 32),

          // Account section
          const Text('Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Delete Account'),
            subtitle: const Text('Request permanent account deletion'),
            onTap: () => _requestDeletion(context),
          ),

          const Divider(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Logout',
              color: AppColors.error,
              icon: Icons.logout,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),

          const SizedBox(height: 32),

          // Version
          const Center(
            child: Text(
              'Battle Squad v1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _requestDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Your account will be permanently deleted after a 7-day grace period. '
          'You can cancel during this period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final api = ref.read(apiClientProvider);
                await api.post('/account/deletion/request');
                if (context.mounted) {
                  showSuccessSnackbar(context, 'Deletion requested. 7-day grace period started.');
                }
              } catch (e) {
                if (context.mounted) showErrorSnackbar(context, '$e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze
git add lib/features/settings/
git commit -m "feat: add full settings screen with logout, account deletion, sound toggle"
```

---

### Task 20: Final Integration & Polish

**Files:**
- Modify: `lib/core/ws/ws_events.dart` (fix PlayerDamaged parsing for array data)
- Verify all imports compile
- Create: `lib/core/providers/core_providers.dart` (update if needed)

- [ ] **Step 1: Fix any remaining import issues**

Run full analysis and fix any compile errors:

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter analyze 2>&1 | head -50
```

Fix any reported issues (missing imports, type mismatches, etc).

- [ ] **Step 2: Run all tests**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter test
```

- [ ] **Step 3: Verify app builds**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
flutter build apk --debug 2>&1 | tail -5
```

- [ ] **Step 4: Create CLAUDE.md for the Flutter project**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working with the Battle Squad Flutter client.

## Build & Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run                  # Run on connected device/emulator
flutter build apk --debug   # Build Android APK
flutter build ios --debug    # Build iOS (requires macOS)
```

## Architecture

Feature-first structure under `lib/`:
- `core/` — API client (Dio), WebSocket manager, auth (token storage + provider), router (GoRouter), theme
- `features/` — Each feature has its own screen, provider, and widgets
- `shared/` — Models (JSON serializable) and reusable widgets

## Key Patterns

- **State:** Riverpod (StateNotifier + AsyncValue for API calls)
- **Routing:** GoRouter with auth guard redirect
- **API:** Dio with auth interceptor (auto-refresh 401)
- **WebSocket:** `WsManager` singleton, typed events via sealed class `WsEvent`, parsed by `parseWsEvent()`
- **Game:** Flame engine (`BattleGame`) embedded in Flutter via `GameWidget`, HUD as Flutter overlay

## Server Connection

- API Server: `http://localhost:8080` (configurable in `core/providers/core_providers.dart`)
- Game Server: `ws://localhost:8081` (same file)

## Tests

```bash
flutter test                                    # All tests
flutter test test/core/api/api_client_test.dart  # Specific test
flutter test test/features/match/terrain_test.dart
```
```

- [ ] **Step 5: Final commit**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
git add -A
git commit -m "feat: final integration, CLAUDE.md, verify all builds pass"
```

- [ ] **Step 6: Push to remote**

```bash
cd /Users/inspius/Desktop/Porojet/github.com/battle-squad-v1
git push -u origin main
```
