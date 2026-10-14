# Client-Server Sync Update Spec

**Date:** 2026-07-07
**Purpose:** Update Flutter client to match all server features that are missing or incomplete.

---

## 1. Ranked Lobby & Matchmaking (NEW Screen)

### Overview
Server has a full ranked 2v2 lobby system. Client needs a new `RankedLobbyScreen` and lobby provider.

### New Screen: `RankedLobbyScreen`
- Create/Join lobby for ranked 2v2
- Display lobby members (max 2 per team)
- Loadout selection (character + items) before queueing
- Start Queue / Cancel Queue buttons (host only)
- States: `preparing` -> `in_queue` -> `in_match`
- "Searching for match..." animation during queue
- "Match Found" transition -> navigate to match screen
- Return to lobby after match ends

### WebSocket Events (Client -> Server)
| Event | Payload |
|-------|---------|
| `CreateLobby` | `{}` |
| `JoinLobby` | `{lobbyId}` |
| `LeaveLobby` | `{}` |
| `UpdateLoadout` | `{characterId?, items?}` |
| `StartQueue` | `{}` |
| `CancelQueue` | `{}` |

### WebSocket Events (Server -> Client)
| Event | Payload |
|-------|---------|
| `LobbyUpdated` | `LobbyState` (lobbyId, hostPlayerId, members[], status, queueEntryId) |
| `QueueStarted` | `{queueEntryId}` |
| `QueueCancelled` | `{reason}` |
| `MatchFound` | `{matchId, battleRoomId, teams}` |
| `LobbyDisbanded` | `{reason}` |
| `ReturnToLobby` | `{lobbyId}` |
| `LobbyError` | `{code, message}` |

### Data Models
```dart
class LobbyState {
  String lobbyId, hostPlayerId, status; // preparing, in_queue, in_match
  List<LobbyMember> members;
  String? queueEntryId;
}

class LobbyMember {
  String playerId, displayName;
  String? characterId;
  List<String> items;
  int rating;
  String tier;
}
```

### Navigation
- Add "Ranked" button on LobbyScreen -> navigates to `/ranked-lobby`
- Route: `/ranked-lobby` and `/ranked-lobby/:id` (join existing)
- After match ends with `ReturnToLobby` event -> navigate back to `/ranked-lobby`

---

## 2. Character Progression (NEW Screen)

### Overview
Server has character stat allocation system. Client needs a `CharacterDetailScreen`.

### New Screen: `CharacterDetailScreen`
- Grid of owned characters from `GET /player/characters`
- Tap character -> show detail with stats (HP, Defense, bonus points)
- Stat allocation UI: +/- buttons for HP and Defense
- Available stat points display
- "Allocate" button -> `POST /player/character/allocate-stats`
- "Reset Stats" button -> `POST /player/character/reset-stats`

### API Endpoints
| Method | Endpoint | Payload |
|--------|----------|---------|
| GET | `/player/characters` | - |
| POST | `/player/character/allocate-stats` | `{characterId, hp, defense}` |
| POST | `/player/character/reset-stats` | `{characterId}` |

### Data Models
```dart
class PlayerCharacter {
  String playerId, characterId;
  int bonusHp, bonusDefense, availablePoints;
  String unlockedAt;
}
```

### Navigation
- Add from ProfileScreen or as a new bottom nav tab
- Route: `/characters` and `/characters/:id`

---

## 3. IAP Gem Shop (NEW Tab in ShopScreen)

### Overview
Server has IAP product listing and receipt verification. Client needs a Gem purchase tab.

### Update: ShopScreen with Tabs
- Tab 1: "Items" (existing shop offers)
- Tab 2: "Gems" (IAP products)
- Gem tab shows products from `GET /iap/products`
- Each product card: gem amount + bonus, price USD
- Tap -> trigger platform purchase (in_app_purchase plugin)
- On success -> verify with `POST /iap/verify`
- On verified -> refresh player profile (coin/gem balance)

### API Endpoints
| Method | Endpoint | Payload |
|--------|----------|---------|
| GET | `/iap/products` | - |
| POST | `/iap/verify` | `{productId, platform, purchaseToken}` |

### Data Models
```dart
class IAPProduct {
  String productId, platformSkuId;
  int gemAmount, bonusGemAmount;
  double priceUsd;
  bool isActive;
}
```

---

## 4. Gift Code (NEW Dialog in SettingsScreen)

### Overview
Server has gift code redemption. Client needs a dialog.

### Update: SettingsScreen
- Add "Redeem Gift Code" button
- Opens dialog with text input + "Redeem" button
- On success -> show reward popup (coins, gems, items received)
- On error -> show error message

### API Endpoint
| Method | Endpoint | Payload |
|--------|----------|---------|
| POST | `/giftcode/redeem` | `{code}` |

### Response Model
```dart
class GiftCodeReward {
  int rewardCoin, rewardGem;
  List<String> rewardItems;
}
```

---

## 5. Player Report (NEW Dialog)

### Overview
Server has player reporting. Client needs a report dialog accessible from match result.

### New Widget: `ReportPlayerDialog`
- Accessible from `MatchResultDialog` -> "Report Player" button
- Select target player from opponent list
- Select category: cheat, abuse, afk, payment_fraud, other
- Optional description text field
- Submit -> `POST /report/player`
- Show success/error feedback

### API Endpoint
| Method | Endpoint | Payload |
|--------|----------|---------|
| POST | `/report/player` | `{targetPlayerId, matchId, category, description}` |

---

## 6. Updates to Existing Screens

### 6a. Season Reward Claim (RankingScreen)
- Add claim button when season status is `ended` or `reward_granting`
- Call `POST /rank/reward/claim` with `{seasonId, tier}`
- Show reward popup on success

### 6b. Account Deletion Cancel/Status (SettingsScreen)
- On load: check `GET /account/deletion/status`
- If status is `pending_deletion`: show cancel button + scheduled date
- Cancel button calls `POST /account/deletion/cancel`
- Update UI to reflect active status after cancel

### 6c. OAuth Login + Link Provider (LoginScreen + SettingsScreen)
- LoginScreen: Add "Sign in with Google" and "Sign in with Apple" buttons
- Call `POST /auth/provider-login` with `{provider, idToken}`
- SettingsScreen: Add "Link Google Account" / "Link Apple Account" buttons
- Call `POST /auth/link-provider` with `{provider, idToken}`
- Use `google_sign_in` and `sign_in_with_apple` packages

### 6d. Shop Purchase History (ShopScreen)
- Add "Purchase History" section or tab
- Fetch `GET /shop/purchases`
- Display list: item name, price, date, status

### 6e. App Version Check (SplashScreen)
- On splash: call `GET /app/version-policy?platform=android|ios`
- If current version < minimum -> show force update dialog (non-dismissible)
- If current version < recommended -> show optional update dialog

### 6f. App Remote Config (Core)
- Fetch `GET /app/config` on app startup
- Store in provider for feature flags and remote settings
- Use for conditional feature toggling throughout the app

---

## Implementation Order

1. Ranked Lobby & Matchmaking
2. Character Progression
3. IAP Gem Shop
4. Gift Code
5. Player Report
6. Update existing screens (6a-6f)
