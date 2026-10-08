import 'package:dio/dio.dart';
import '../auth/secure_session_store.dart';
import 'api_config.dart';
import 'api_response.dart';

class ApiClient {
  ApiClient(this._session)
      : dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
          validateStatus: (code) => code != null && code < 500,
        )) {
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (options.extra['noAuth'] != true) {
        final token = await _session.readValidToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }, onResponse: (response, handler) async {
      if (response.statusCode == 401 &&
          response.requestOptions.extra['noAuth'] != true) {
        await _session.clear();
      }
      handler.next(response);
    }));
  }

  final SecureSessionStore _session;
  final Dio dio;

  Future<ApiResponse<T>> mutate<T>(
      String path, String method, T Function(Object?) parse,
      {Map<String, dynamic>? payload}) async {
    try {
      final response = await dio.request<Object?>(
        path,
        data: payload,
        options: Options(method: method),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiFailure('Unexpected server response.',
            statusCode: response.statusCode);
      }
      final result = ApiResponse<T>.fromJson(body, parse);
      if ((response.statusCode ?? 500) >= 400 || !result.success) {
        throw ApiFailure(
            result.message.isNotEmpty ? result.message : 'Request failed.',
            statusCode: response.statusCode);
      }
      return result;
    } on DioException catch (_) {
      throw const ApiFailure('Unable to send request. Check your connection.');
    }
  }

  Future<ApiResponse<T>> get<T>(String path, T Function(Object?) parse) async {
    try {
      final response = await dio.get<Object?>(path);
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiFailure('Unexpected server response.',
            statusCode: response.statusCode);
      }
      final result = ApiResponse<T>.fromJson(body, parse);
      if ((response.statusCode ?? 500) >= 400 || !result.success) {
        throw ApiFailure(
            result.message.isNotEmpty ? result.message : 'Request failed.',
            statusCode: response.statusCode);
      }
      return result;
    } on DioException catch (_) {
      throw const ApiFailure('Unable to load data. Check your connection.');
    }
  }

  Future<ApiResponse<T>> post<T>(
      String path, Map<String, dynamic> payload, T Function(Object?) parse,
      {bool anonymous = false}) async {
    try {
      final response = await dio.post<Object?>(path,
          data: payload, options: Options(extra: {'noAuth': anonymous}));
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiFailure('Unexpected server response.',
            statusCode: response.statusCode);
      }
      final result = ApiResponse<T>.fromJson(body, parse);
      if ((response.statusCode ?? 500) >= 400 || !result.success) {
        throw ApiFailure(
            result.message.isNotEmpty ? result.message : 'Request failed.',
            statusCode: response.statusCode);
      }
      return result;
    } on DioException catch (error) {
      throw ApiFailure(error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout
          ? 'Connection timed out. Please retry.'
          : 'Unable to connect. Check your connection.');
    }
  }
}
