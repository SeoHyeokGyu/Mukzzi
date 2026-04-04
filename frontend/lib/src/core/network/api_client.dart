import 'package:dio/dio.dart';

class ApiClient {
  late Dio _dio;
  static const String _baseUrl = 'http://localhost:8080/api';

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Bearer 토큰 추가 로직 필요
          return handler.next(options);
        },
        onError: (error, handler) {
          // 에러 처리 로직 필요
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // 기본 GET 요청
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // 기본 POST 요청
  Future<dynamic> post(String path, {required dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // 기본 PATCH 요청
  Future<dynamic> patch(String path, {required dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // 기본 DELETE 요청
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
