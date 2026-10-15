import 'dart:convert';
import 'dart:typed_data';

import 'package:battle_squad_v1/core/api/api_client.dart';
import 'package:battle_squad_v1/core/api/api_interceptor.dart';
import 'package:battle_squad_v1/core/auth/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps tokens in memory instead of the platform secure storage.
class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage() {
    cachedAccessToken = 'old-access';
    cachedRefreshToken = 'old-refresh';
    cachedPlayerId = 'p1';
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String playerId,
  }) async {
    cachedAccessToken = accessToken;
    cachedRefreshToken = refreshToken;
    cachedPlayerId = playerId;
  }
}

/// Answers each request with the handler registered for its path; a handler
/// returns (status, body) or throws a DioException.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Object) Function(RequestOptions)> routes;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    final (status, body) = routes[options.path]!(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _unauthorized = (401, {'success': false, 'error': {'code': 'AUTH_UNAUTHORIZED', 'message': 'expired'}});
const _newTokens = (200, {'success': true, 'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'}});

(int, Object) _timeout(RequestOptions o) =>
    throw DioException(requestOptions: o, type: DioExceptionType.receiveTimeout);

void main() {
  late int logouts;

  /// Main client: every purchase is answered 401 (expired access token).
  /// Refresh client: serves /auth/refresh and the retried purchase.
  (Dio, _FakeAdapter) build(Map<String, (int, Object) Function(RequestOptions)> refreshRoutes) {
    logouts = 0;
    final refreshAdapter = _FakeAdapter(refreshRoutes);
    final refreshDio = Dio()..httpClientAdapter = refreshAdapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = _FakeAdapter({'/shop/purchase': (_) => _unauthorized})
      ..interceptors.add(AuthInterceptor(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://test',
        onRefreshFailed: () async => logouts++,
        refreshDio: refreshDio,
      ));
    return (dio, refreshAdapter);
  }

  Future<ApiException> purchaseError(Dio dio) async {
    try {
      await dio.post<dynamic>('/shop/purchase', data: {'offerId': 'medkit'});
    } on DioException catch (e) {
      return ApiException.fromDioError(e);
    }
    fail('purchase did not fail');
  }

  test('a retry that times out surfaces as a network error, not the 401', () async {
    final (dio, refresh) = build({
      '/auth/refresh': (_) => _newTokens,
      '/shop/purchase': _timeout,
    });

    final e = await purchaseError(dio);

    expect(refresh.calls, ['/auth/refresh', '/shop/purchase']);
    expect(e.code, 'NETWORK_ERROR');
    expect(e.isRejected, isFalse, reason: 'the idempotency key must be kept');
    expect(logouts, 0);
  });

  test('a retry that the server rejects surfaces its own error', () async {
    final (dio, _) = build({
      '/auth/refresh': (_) => _newTokens,
      '/shop/purchase': (_) => (400, {'success': false, 'error': {'code': 'SHOP_INSUFFICIENT_BALANCE', 'message': 'poor'}}),
    });

    final e = await purchaseError(dio);

    expect(e.code, 'SHOP_INSUFFICIENT_BALANCE');
    expect(logouts, 0);
  });

  test('a successful retry resolves the original request', () async {
    final (dio, _) = build({
      '/auth/refresh': (_) => _newTokens,
      '/shop/purchase': (o) {
        expect(o.headers['Authorization'], 'Bearer new-access');
        return (200, {'success': true, 'data': {'purchaseId': 'x'}});
      },
    });

    final res = await dio.post<dynamic>('/shop/purchase');

    expect(unwrapEnvelope(res.data), {'purchaseId': 'x'});
  });

  test('a rejected refresh logs out and keeps the original 401', () async {
    final (dio, refresh) = build({'/auth/refresh': (_) => _unauthorized});

    final e = await purchaseError(dio);

    expect(refresh.calls, ['/auth/refresh']);
    expect(e.statusCode, 401);
    expect(logouts, 1);
  });

  test('a refresh lost to the network does not log out', () async {
    final (dio, _) = build({'/auth/refresh': _timeout});

    final e = await purchaseError(dio);

    expect(e.statusCode, 401);
    expect(logouts, 0);
  });
}
