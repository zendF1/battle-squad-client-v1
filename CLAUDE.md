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

## Code Generation

After modifying any `@JsonSerializable` model:
```bash
dart run build_runner build --delete-conflicting-outputs
```
