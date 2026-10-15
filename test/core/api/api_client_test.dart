import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_squad_v1/core/api/api_client.dart';

void main() {
  group('ApiException', () {
    test('parses server error response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'error': {'code': 'BAD_REQUEST', 'message': 'Invalid input'}},
        ),
      );
      final apiError = ApiException.fromDioError(error);
      expect(apiError.code, 'BAD_REQUEST');
      expect(apiError.message, 'Invalid input');
      expect(apiError.statusCode, 400);
    });

    test('handles network error without response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'Connection timeout',
      );
      final apiError = ApiException.fromDioError(error);
      expect(apiError.code, 'NETWORK_ERROR');
      expect(apiError.statusCode, 0);
    });
  });

  group('unwrapEnvelope', () {
    test('returns data of a success envelope', () {
      expect(unwrapEnvelope({'success': true, 'data': {'gem': 5}}), {'gem': 5});
      expect(unwrapEnvelope({'success': true, 'data': [1, 2]}), [1, 2]);
    });

    test('returns null when a success envelope has no data', () {
      expect(unwrapEnvelope({'success': true}), isNull);
    });

    test('leaves bodies without an envelope unchanged', () {
      expect(unwrapEnvelope({'gem': 5}), {'gem': 5});
      expect(unwrapEnvelope([1]), [1]);
    });
  });

  test('ApiException.isRejected is true only for 4xx', () {
    ApiException e(int status) =>
        ApiException(code: 'X', message: 'x', statusCode: status);
    expect(e(409).isRejected, isTrue);
    expect(e(0).isRejected, isFalse);
    expect(e(500).isRejected, isFalse);
  });

  test('parses error envelope', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 409,
        data: {
          'success': false,
          'error': {'code': 'SHOP_ALREADY_OWNED', 'message': 'owned', 'correlationId': 'c1'},
        },
      ),
    );
    final apiError = ApiException.fromDioError(error);
    expect(apiError.code, 'SHOP_ALREADY_OWNED');
    expect(apiError.isRejected, isTrue);
  });
}
