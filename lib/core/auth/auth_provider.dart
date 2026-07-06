import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/token_storage.dart';
import '../providers/core_providers.dart';
import '../ws/ws_manager.dart';

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
    bool clearError = false,
    bool clearDisplayName = false,
    bool clearPlayerId = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      playerId: clearPlayerId ? null : (playerId ?? this.playerId),
      displayName:
          clearDisplayName ? null : (displayName ?? this.displayName),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final WsManager _wsManager;

  AuthNotifier({
    required this._tokenStorage,
    required this._apiClient,
    required this._wsManager,
  }) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(loading: true, clearError: true);

    final hasTokens = await _tokenStorage.hasTokens;
    if (!hasTokens) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        loading: false,
      );
      return;
    }

    try {
      final data = await _apiClient.get('/player/profile');
      final playerId = data['playerId'] as String? ?? data['player_id'] as String?;
      final displayName = data['displayName'] as String? ?? data['display_name'] as String?;
      final token = await _tokenStorage.accessToken;
      if (token != null) {
        _wsManager.connect(token);
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        playerId: playerId,
        displayName: displayName,
        loading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Interceptor already tried refresh; if we still get 401, fail.
        await _tokenStorage.clearAll();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          loading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          loading: false,
          error: e.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> guestLogin() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final deviceId = await _getDeviceId();
      final data = await _apiClient.post(
        '/auth/guest-login',
        data: {'deviceInstallId': deviceId},
      );

      final accessToken = data['accessToken'] as String? ?? data['access_token'] as String?;
      final refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String?;
      final playerId = data['playerId'] as String? ?? data['player_id'] as String?;
      final displayName = data['displayName'] as String? ?? data['display_name'] as String?;

      if (accessToken == null || refreshToken == null || playerId == null) {
        state = state.copyWith(
          loading: false,
          error: 'Invalid response from server',
        );
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        playerId: playerId,
      );

      _wsManager.connect(accessToken);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        playerId: playerId,
        displayName: displayName,
        loading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    final rt = await _tokenStorage.refreshToken;
    if (rt != null) {
      try {
        await _apiClient.post('/auth/logout', data: {'refreshToken': rt});
      } catch (_) {
        // Ignore errors on logout
      }
    }

    _wsManager.disconnect();
    await _tokenStorage.clearAll();

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearPlayerId: true,
      clearDisplayName: true,
      clearError: true,
      loading: false,
    );
  }

  Future<String> _getDeviceId() async {
    if (kIsWeb) {
      return _fallbackId();
    }
    final deviceInfo = DeviceInfoPlugin();
    try {
      final info = await deviceInfo.deviceInfo;
      final data = info.data;
      // Try common fields across platforms
      final id = data['id'] ?? data['identifierForVendor'] ?? data['model'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
    } catch (_) {
      // Fall through to fallback
    }
    return _fallbackId();
  }

  String _fallbackId() {
    return 'flutter-guest-${DateTime.now().millisecondsSinceEpoch}';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    tokenStorage: ref.read(tokenStorageProvider),
    apiClient: ref.read(apiClientProvider),
    wsManager: ref.read(wsManagerProvider),
  );
});
