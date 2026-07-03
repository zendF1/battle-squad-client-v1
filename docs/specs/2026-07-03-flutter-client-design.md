# Battle Squad Flutter Client — Design Spec

## Overview

Flutter client app for Battle Squad — turn-based artillery PvP game. Connects to existing Go server (API Server :8080, Game Server :8081 WebSocket).

**Target:** iOS + Android (mobile only)
**Tech stack:** Flutter + Flame (game engine) + Riverpod (state) + GoRouter (navigation) + Dio (HTTP) + web_socket_channel (WS)
**Assets:** Placeholder text/shapes, no real art assets yet

---

## Architecture: Feature-First

```
lib/
├── core/
│   ├── api/            # Dio HTTP client, interceptors, error handling
│   ├── ws/             # WebSocket manager, event stream, message envelope
│   ├── auth/           # Token storage, auth state
│   ├── router/         # GoRouter config, auth guard
│   ├── theme/          # Dark theme, colors, text styles
│   └── providers/      # Core providers (auth, http, ws, gamedata)
├── features/
│   ├── auth/           # Splash, login screen
│   ├── lobby/          # Room list, create/join room, quick match
│   ├── room/           # Room waiting, character select, item select
│   ├── match/          # Flame game, HUD overlay, result screen
│   ├── profile/        # Profile view/edit, inventory, match history
│   ├── shop/           # Shop offers, purchase
│   ├── mission/        # Daily missions, achievements
│   ├── ranking/        # Leaderboard, my rank, season info
│   └── settings/       # Logout, account deletion, sound toggle
├── shared/
│   ├── widgets/        # Reusable widgets (buttons, cards, dialogs)
│   └── models/         # Shared data models
└── main.dart
```

---

## Section 1: Core Infrastructure

### API Client
- `HttpClient` wrapper around `dio`
- Base URL configurable (default `http://localhost:8080`)
- JWT interceptor: auto-attach `Authorization: Bearer <token>`, auto-refresh on 401
- Token storage: `flutter_secure_storage`
- Response mapping to typed models
- Error handling: parse server error codes, surface to UI

### WebSocket Client
- `WebSocketManager` singleton using `web_socket_channel`
- Connect to `ws://<host>:8081/ws?token=<jwt>`
- Auto-reconnect with exponential backoff (1s, 2s, 4s, 8s, max 30s)
- Message envelope: `{"event": "...", "data": {...}}`
- Parse incoming messages into typed event objects
- Event stream via `StreamController` → Riverpod providers listen
- Ping/pong handling (server pings every ~54s, pong wait 60s)
- Max message size: 4096 bytes

### Auth Flow
1. Splash screen → check stored token
2. Valid token → connect WS → navigate to Home
3. Expired token → attempt refresh via `POST /auth/refresh`
4. Refresh fails → navigate to Login
5. Login screen: Guest login button → `POST /auth/guest-login` with `deviceInstallId`
6. On login success: store tokens, connect WebSocket, navigate to Home

### Router (GoRouter)
- Auth guard: redirect to `/login` if not authenticated
- Routes:
  - `/splash` — Splash/loading screen
  - `/login` — Guest login
  - `/home` — Bottom nav shell (play, profile, shop, missions, ranking)
  - `/room/:id` — Room waiting screen
  - `/match` — Match screen (Flame game + HUD)
  - `/settings` — Settings screen
- Bottom navigation tabs: Play, Profile, Shop, Missions, Ranking

### Theme
- Dark theme as default (game aesthetic)
- Placeholder color palette, easily replaceable
- Consistent text styles and spacing

---

## Section 2: Game Screen (Flame)

### Architecture
- `BattleGame extends FlameGame` embedded in Flutter via `GameWidget`
- Flutter HUD overlay on top of Flame (using `GameWidget.overlayBuilderMap`)
- Flame renders: terrain, players, projectiles, explosions
- Flutter renders: HP bars, turn timer, controls, wind indicator, item slots

### Terrain Rendering
- Generate terrain bitmap 1600x900 using same algorithm as server:
  - `grassland_valley`: `550 + 100*sin(x*0.003) + 40*sin(x*0.01)`
  - `frozen_peak`: `500 + 120*sin(x*0.005) + 60*cos(x*0.015)`
  - `steel_base`: stepped platforms (400 for middle sections, 600 elsewhere)
- Render as filled polygon via `CustomPainterComponent`
- Terrain destruction: on `ProjectileResult` with `terrainDestroyed=true`, apply `DestroyCircle` on local bitmap, re-render
- Placeholder colors: green (grassland), white (frozen), grey (steel)

### Players
- `PlayerComponent extends PositionComponent`
- Placeholder: colored rectangle with text label (name + HP)
- Character colors: rookie=blue, tanko=red, spark=yellow, flora=green
- Position updates from server events (`PlayerMoved`, `MatchStarted`)

### Projectile Animation
- Server sends `path[]` (list of `{position, velocity, time}`)
- Client animates circle/dot along path positions using elapsed time
- At `explosionPoint` → spawn explosion effect (expanding circle with fade-out)
- Duration matches server simulation timestamps

### Camera
- `CameraComponent` with viewport fitting 1600x900
- Follow active player during their turn
- Follow projectile during flight
- Smooth transitions between targets

### HUD Overlay (Flutter Widgets)
- **Top bar:** Turn timer countdown, wind indicator (arrow direction + power number), current turn player name
- **Bottom bar:** Angle slider (0°-180°), Power bar (0-100), Shoot button
- **Side panels:** Item slots (max 3 buttons), Skill button (with cooldown number badge)
- **Player HP bars:** Floating above each player, positioned relative to game coordinates
- Controls enabled only during local player's turn

### Controls Flow
1. Player's turn starts → enable angle/power controls
2. Adjust angle slider or tap terrain to aim
3. Adjust power bar
4. Choose action mode: weapon (default), skill, or item
5. Tap Shoot → send `{"event":"Shoot","data":{angle, power, actionMode}}`
6. Disable controls → animate projectile
7. Receive `ProjectileResult` + `PlayerDamaged` → update visuals
8. Move: drag player left/right → send `{"event":"Move","data":{direction, targetX}}`
9. End Turn button or auto-end on timer expiry

---

## Section 3: Features

### Lobby (Home — Play Tab)
- Room list from `GET /rooms` with pull-to-refresh
- Room card: mode badge, map name, player count (e.g. "1/2"), lock icon if password
- Create Room button → dialog: select mode (1v1/2v2), map, optional password
- Quick Match button → create room without password, auto-ready
- Tap room card → JoinRoom (prompt password if locked)

### Room Waiting
- Player slots: 2 for 1v1, 4 for 2v2, with team color background
- Character select: 4 character cards with name + stats (HP, DMG, DEF) + placeholder icon
- Item select: grid of owned items, tap to toggle (max 3 selected), show quantity
- Ready button (toggle) for non-host players
- Start button for host (enabled when all players ready + room full)
- Map preview: colored rectangle with map name
- Leave button → back to lobby

### Match Result
- Overlay popup after `MatchEnded`
- Large Win/Lose/Draw text
- Stats: EXP gained, Coins gained, Rating change (+/-)
- Player stats: damage dealt, kills, shots fired, accuracy
- Buttons: Back to Room / Back to Lobby

### Profile (Profile Tab)
- Avatar: circle with first letter of display name
- Display name (tap to edit → `PUT /player/profile`)
- Level + EXP progress bar
- Coin + Gem balance display
- Match history list (paginated from `GET /player/match-history`)
  - Each entry: mode, map, result (win/loss/draw), date
- Inventory section: grid of owned items with quantities

### Shop (Shop Tab)
- List of offers from `GET /shop/offers`
- Offer card: item name, placeholder icon, price (coin/gem icon + amount)
- Tap → purchase confirm dialog with idempotency key (uuid v4)
- `POST /shop/purchase` → success popup or error snackbar
- Balance display at top

### Missions (Missions Tab)
- Two sub-tabs: Daily / Achievements
- Mission card: description text, progress bar (currentValue/requiredValue), claim button
- Claim button enabled when progress complete + not yet claimed
- `POST /missions/claim` → reward popup (coins, gems, items)

### Ranking (Ranking Tab)
- My rank card at top: tier text (Bronze III, etc.), rating number, W/L/D stats
- Season info: season name, end date
- Leaderboard list: rank #, player name, rating, tier
- Paginated from `GET /rank/leaderboard`
- Claim season reward button when available

### Settings
- Accessible from profile or app bar
- Logout button → `POST /auth/logout` → clear tokens → navigate to Login
- Account deletion: request → confirm dialog → `POST /account/deletion/request`
- Cancel deletion: `POST /account/deletion/cancel`
- Sound toggle (placeholder, no audio implementation yet)
- App version display

---

## Section 4: Data Flow & State Management

### Riverpod Providers

```dart
// Core
authProvider          → AsyncNotifier: token management, login/logout
httpClientProvider    → Provider: configured dio instance
wsManagerProvider     → Provider: WebSocket singleton
gameDataProvider      → FutureProvider: game config (characters, weapons, skills, items, maps)

// Features
profileProvider       → AsyncNotifier: player profile + balance
inventoryProvider     → AsyncNotifier: player inventory items
roomListProvider      → AsyncNotifier: active rooms from REST API
roomStateProvider     → StreamNotifier: current room state from WS events
matchStateProvider    → StreamNotifier: match state from WS events
shopOffersProvider    → FutureProvider: shop offers list
missionsProvider      → AsyncNotifier: daily missions + achievements
rankProvider          → AsyncNotifier: my rank + leaderboard
matchHistoryProvider  → AsyncNotifier: paginated match history
```

### WebSocket Event Flow

```
Server WS message
  → WebSocketManager parses envelope
  → Emits typed event to eventStream
  → roomStateProvider listens: RoomUpdated, RoomError
  → matchStateProvider listens: MatchStarted, TurnStarted, TurnTimerTick,
      ProjectileResult, PlayerDamaged, PlayerMoved, ItemUsed, SkillUsed,
      MatchEnded, MatchStateSync
  → UI rebuilds via ref.watch()
```

### Offline / Error Handling
- WS disconnect → show "Reconnecting..." banner, auto-reconnect with backoff
- On reconnect + in active match → send `Reconnect` event → receive `MatchStateSync`
- API errors → parse error code → show snackbar with localized message
- Token expired during API call → interceptor auto-refreshes, retries request once
- Network offline → show offline indicator, queue no actions

---

## Section 5: Server Protocol Reference

### WebSocket Connection
- URL: `ws://<host>:8081/ws?token=<jwt>`
- Message format: `{"event": "string", "data": {}}`

### Client → Server Events

| Event | Data |
|-------|------|
| CreateRoom | `{mode, mapId, password?}` |
| JoinRoom | `{roomId, password?}` |
| ChangeTeam | `{teamId}` |
| SelectCharacter | `{characterId}` |
| SelectItems | `{items: []}` |
| Ready | `{}` |
| StartMatch | `{}` |
| Leave | `{}` |
| Move | `{direction, targetX, clientTimestamp}` |
| Shoot | `{angle, power, actionMode, itemId?, targetX?, clientTimestamp}` |
| UseItem | `{itemId, targetPosition?, clientTimestamp}` |
| EndTurn | `{}` |
| Reconnect | `{}` |

### Server → Client Events

| Event | Description |
|-------|-------------|
| RoomUpdated | Full room state |
| RoomError | Error with code + message |
| MatchStarted | Full match state |
| TurnStarted | Turn index, current player, wind, move energy |
| TurnTimerTick | Seconds remaining |
| PlayerMoved | Player position + remaining energy |
| ProjectileResult | Path, hit info, explosion point, terrain destroyed |
| PlayerDamaged | Array of {playerId, damage, hp, isAlive} |
| SkillUsed | Player, skill, HP if heal |
| ItemUsed | Player, item, updated state |
| MatchEnded | Winning team, rewards per player |
| MatchStateSync | Full match state (reconnect) |

### REST API Base URL: `http://<host>:8080`

Key endpoints used by client:
- `POST /auth/guest-login` — `{deviceInstallId}`
- `POST /auth/refresh` — `{refreshToken}`
- `POST /auth/logout` — `{refreshToken}`
- `GET /player/profile`, `PUT /player/profile`
- `GET /player/inventory`
- `GET /player/match-history?page=&limit=`
- `GET /shop/offers`, `POST /shop/purchase`
- `GET /missions/daily`, `GET /missions/achievements`, `POST /missions/claim`
- `GET /rank/me`, `GET /rank/leaderboard`, `POST /rank/reward/claim`
- `GET /rooms`
- `GET /app/version-policy`, `GET /app/config`
- `POST /report/player`
- `POST /account/deletion/request`, `POST /account/deletion/cancel`

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.x
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x
  dio: ^5.x
  web_socket_channel: ^3.x
  flutter_secure_storage: ^9.x
  device_info_plus: ^10.x
  uuid: ^4.x
  intl: ^0.19.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.x
  build_runner: ^2.x
  flutter_lints: ^4.x
```
