import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  factory ApiException.fromDioError(DioException error) {
    debugPrint('[API ERROR] type=${error.type} message=${error.message} url=${error.requestOptions.uri}');
    debugPrint('[API ERROR] response=${error.response?.statusCode} data=${error.response?.data}');
    final response = error.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
        final errorMap = data['error'] as Map<String, dynamic>;
        return ApiException(
          code: (errorMap['code'] as String?) ?? 'UNKNOWN_ERROR',
          message: (errorMap['message'] as String?) ?? 'An unknown error occurred',
          statusCode: response.statusCode ?? 0,
        );
      }
      return ApiException(
        code: 'SERVER_ERROR',
        message: 'Unexpected server response',
        statusCode: response.statusCode ?? 0,
      );
    }
    return ApiException(
      code: 'NETWORK_ERROR',
      message: error.message ?? 'Network error occurred',
      statusCode: 0,
    );
  }

  /// The server answered and refused the request (4xx), so it changed nothing.
  /// Network errors (0) and server errors (5xx) leave the outcome unknown.
  bool get isRejected => statusCode >= 400 && statusCode < 500;

  @override
  String toString() => 'ApiException($code): $message';
}

/// Returns the payload of a `{"success": true, "data": ...}` response.
/// Bodies without the envelope are returned unchanged.
dynamic unwrapEnvelope(dynamic body) {
  if (body is Map<String, dynamic> && body['success'] == true) {
    return body['data'];
  }
  return body;
}

class ApiClient {
  late final Dio _dio;

  ApiClient({required String baseUrl, List<Interceptor>? interceptors}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (msg) => debugPrint('[DIO] $msg'),
    ));
  }

  Map<String, dynamic> _normalize(dynamic body) {
    final data = unwrapEnvelope(body);
    if (data is Map<String, dynamic>) return data;
    if (data is List) return {'data': data};
    return {};
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParams,
      );
      return _normalize(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return _normalize(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);
      return _normalize(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
