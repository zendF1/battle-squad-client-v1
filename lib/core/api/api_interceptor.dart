import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/token_storage.dart';
import 'api_client.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final String baseUrl;
  final Future<void> Function() onRefreshFailed;

  late final Dio _refreshDio;
  bool _isRefreshing = false;

  AuthInterceptor({
    required this.tokenStorage,
    required this.baseUrl,
    required this.onRefreshFailed,
    @visibleForTesting Dio? refreshDio,
  }) {
    _refreshDio = refreshDio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Use cached token synchronously — no async needed
    final token = tokenStorage.cachedAccessToken;
    debugPrint('[AUTH] ${options.method} ${options.path} token=${token != null ? "yes" : "no"}');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      handler.next(err);
      return;
    }

    // 1. Refresh. The original request got 401, so the server did not run it:
    // if refreshing fails, that 401 is the true outcome.
    _isRefreshing = true;
    final String? newAccess;
    try {
      newAccess = await _refreshTokens();
    } on DioException catch (refreshErr) {
      // Only a refresh the server rejected ends the session; a network or
      // server error leaves the tokens as they are.
      final status = refreshErr.response?.statusCode ?? 0;
      if (status >= 400 && status < 500) await onRefreshFailed();
      handler.next(err);
      return;
    } finally {
      _isRefreshing = false;
    }
    if (newAccess == null) {
      await onRefreshFailed();
      handler.next(err);
      return;
    }

    // 2. Retry. Whatever this attempt returns (success, business error,
    // timeout) is the real outcome; never swap it for the original 401, since
    // the retry may have been applied even if its response was lost.
    final retryOptions = err.requestOptions;
    retryOptions.headers['Authorization'] = 'Bearer $newAccess';
    try {
      handler.resolve(await _refreshDio.fetch(retryOptions));
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  /// Returns the new access token, or null when the refresh response has none.
  Future<String?> _refreshTokens() async {
    final refreshToken = tokenStorage.cachedRefreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _refreshDio.post<dynamic>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final payload = unwrapEnvelope(response.data);
    if (payload is! Map<String, dynamic>) return null;

    final newAccess = payload['accessToken'] as String? ?? payload['access_token'] as String?;
    final newRefresh = payload['refreshToken'] as String? ?? payload['refresh_token'] as String?;
    if (newAccess == null || newRefresh == null) return null;

    await tokenStorage.saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
      playerId: tokenStorage.cachedPlayerId ?? '',
    );
    return newAccess;
  }
}
