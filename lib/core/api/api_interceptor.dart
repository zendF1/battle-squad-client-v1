import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/token_storage.dart';

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
  }) {
    _refreshDio = Dio(
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
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = tokenStorage.cachedRefreshToken;
        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          await onRefreshFailed();
          handler.next(err);
          return;
        }

        final response = await _refreshDio.post<dynamic>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final data = response.data as Map<String, dynamic>?;
        if (data != null) {
          final newAccess = data['accessToken'] as String? ?? data['access_token'] as String?;
          final newRefresh = data['refreshToken'] as String? ?? data['refresh_token'] as String?;

          if (newAccess != null && newRefresh != null) {
            await tokenStorage.saveTokens(
              accessToken: newAccess,
              refreshToken: newRefresh,
              playerId: tokenStorage.cachedPlayerId ?? '',
            );

            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retryResponse = await _refreshDio.fetch(retryOptions);
            _isRefreshing = false;
            handler.resolve(retryResponse);
            return;
          }
        }

        _isRefreshing = false;
        await onRefreshFailed();
        handler.next(err);
      } on DioException catch (_) {
        _isRefreshing = false;
        await onRefreshFailed();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
