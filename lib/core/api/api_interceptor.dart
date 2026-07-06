import 'package:dio/dio.dart';
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
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.accessToken;
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
        final refreshToken = await tokenStorage.refreshToken;
        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          await onRefreshFailed();
          handler.next(err);
          return;
        }

        final response = await _refreshDio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final data = response.data;
        if (data != null) {
          final newAccessToken = data['access_token'] as String?;
          final newRefreshToken = data['refresh_token'] as String?;
          final playerId = data['player_id'] as String?;

          if (newAccessToken != null &&
              newRefreshToken != null &&
              playerId != null) {
            await tokenStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
              playerId: playerId,
            );

            // Retry the original request with the new token
            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryDio = Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: retryOptions.connectTimeout,
                receiveTimeout: retryOptions.receiveTimeout,
              ),
            );

            final retryResponse = await retryDio.fetch(retryOptions);
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
