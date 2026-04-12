import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'exceptions.dart';

class ApiClient {
  late Dio _dio;
  final SharedPreferences _prefs;

  ApiClient(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        contentType: 'application/json',
      ),
    );

    // 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _prefs.getString(AppConstants.accessTokenKey);
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          final appException = _handleDioError(error);
          return handler.next(DioException(
            requestOptions: error.requestOptions,
            error: appException,
            response: error.response,
            type: error.type,
            message: appException.message,
          ));
        },
      ),
    );
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(message: '연결 시간이 초과되었습니다.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String? serverMessage;
        if (data is Map && data['error'] != null) {
          serverMessage = data['error']['message'] as String?;
        }

        switch (statusCode) {
          case 400:
            return BadRequestException(message: serverMessage ?? '잘못된 요청입니다.');
          case 401:
            return UnauthorizedException(message: serverMessage ?? '인증이 필요합니다.');
          case 403:
            return UnknownException(message: serverMessage ?? '권한이 없습니다.');
          case 404:
            return NotFoundException(message: serverMessage ?? '요청한 리소스를 찾을 수 없습니다.');
          case 500:
            return ServerException(message: serverMessage ?? '서버 오류가 발생했습니다.');
          default:
            return UnknownException(message: serverMessage ?? '알 수 없는 오류가 발생했습니다.');
        }
      case DioExceptionType.cancel:
        return UnknownException(message: '요청이 취소되었습니다.');
      case DioExceptionType.connectionError:
        return NetworkException(message: '네트워크 연결이 원활하지 않습니다.');
      default:
        return NetworkException(message: '네트워크 오류가 발생했습니다.');
    }
  }

  Dio get dio => _dio;

  // 기본 GET 요청
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  // 기본 POST 요청
  Future<dynamic> post(String path, {required dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  // 기본 PUT 요청
  Future<dynamic> put(String path, {required dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  // 기본 PATCH 요청
  Future<dynamic> patch(String path, {required dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  // 기본 DELETE 요청
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}
