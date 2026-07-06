import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyPlayerId = 'player_id';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions.defaultOptions,
            );

  Future<String?> get accessToken => _storage.read(key: _keyAccessToken);

  Future<String?> get refreshToken => _storage.read(key: _keyRefreshToken);

  Future<String?> get playerId => _storage.read(key: _keyPlayerId);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String playerId,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyPlayerId, value: playerId),
    ]);
  }

  Future<void> clearAll() async {
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
