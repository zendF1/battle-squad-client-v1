import 'package:dio/dio.dart';

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

  @override
  String toString() => 'ApiException($code): $message';
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
  }

  Map<String, dynamic> _normalize(dynamic data) {
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
