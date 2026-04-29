import 'package:dio/dio.dart';
import 'package:mukzzi/src/core/constants/app_constants.dart';
import 'package:mukzzi/src/core/network/exceptions.dart';
import 'package:mukzzi/src/core/storage/token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  // 진행 중인 refresh 요청을 재사용해 중복 호출을 방지한다.
  Future<String?>? _refreshFuture;

  ApiClient(this._tokenStorage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.apiTimeout,
            receiveTimeout: AppConstants.apiTimeout,
            contentType: 'application/json',
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read(AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      final newToken = await _tryRefresh();
      if (newToken != null) {
        // 원래 요청을 새 토큰으로 재시도한다.
        final opts = error.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(_mapError(retryError));
        }
      }
    }
    handler.next(_mapError(error));
  }

  Future<String?> _tryRefresh() async {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture;
  }

  Future<String?> _doRefresh() async {
    final refreshToken =
        await _tokenStorage.read(AppConstants.refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}),
      );
      final newAccessToken =
          response.data['data']['accessToken'] as String?;
      if (newAccessToken != null) {
        await _tokenStorage.write(AppConstants.accessTokenKey, newAccessToken);
      }
      return newAccessToken;
    } on DioException {
      // refresh 실패 시 두 토큰 모두 삭제해 강제 로그아웃 상태로 만든다.
      await _tokenStorage.deleteAll([
        AppConstants.accessTokenKey,
        AppConstants.refreshTokenKey,
      ]);
      return null;
    }
  }

  DioException _mapError(DioException error) {
    final appException = _handleDioError(error);
    return DioException(
      requestOptions: error.requestOptions,
      error: appException,
      response: error.response,
      type: error.type,
      message: appException.message,
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
            return BadRequestException(
                message: serverMessage ?? '잘못된 요청입니다.');
          case 401:
            return UnauthorizedException(
                message: serverMessage ?? '인증이 필요합니다.');
          case 403:
            return UnknownException(message: serverMessage ?? '권한이 없습니다.');
          case 404:
            return NotFoundException(
                message: serverMessage ?? '요청한 리소스를 찾을 수 없습니다.');
          case 500:
            return ServerException(
                message: serverMessage ?? '서버 오류가 발생했습니다.');
          default:
            return UnknownException(
                message: serverMessage ?? '알 수 없는 오류가 발생했습니다.');
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

  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response =
          await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

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
