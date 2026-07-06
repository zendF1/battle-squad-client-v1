import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyPlayerId = 'player_id';

  final FlutterSecureStorage _storage;

  // In-memory cache for sync access (needed by interceptor)
  String? cachedAccessToken;
  String? cachedRefreshToken;
  String? cachedPlayerId;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions.defaultOptions,
            );

  Future<String?> get accessToken async {
    cachedAccessToken ??= await _storage.read(key: _keyAccessToken);
    return cachedAccessToken;
  }

  Future<String?> get refreshToken async {
    cachedRefreshToken ??= await _storage.read(key: _keyRefreshToken);
    return cachedRefreshToken;
  }

  Future<String?> get playerId async {
    cachedPlayerId ??= await _storage.read(key: _keyPlayerId);
    return cachedPlayerId;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String playerId,
  }) async {
    // Update memory cache immediately
    cachedAccessToken = accessToken;
    cachedRefreshToken = refreshToken;
    cachedPlayerId = playerId;

    // Persist in background
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyPlayerId, value: playerId),
    ]);
  }

  Future<void> clearAll() async {
    cachedAccessToken = null;
    cachedRefreshToken = null;
    cachedPlayerId = null;
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyPlayerId),
    ]);
  }

  Future<bool> get hasTokens async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }
}
