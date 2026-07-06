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
}
