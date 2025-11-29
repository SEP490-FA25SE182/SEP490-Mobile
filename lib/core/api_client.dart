import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'config.dart';
import 'secure_store.dart';
import 'failures.dart';

class ApiClient {
  final SecureStore _store;
  final AppConfig _config;

  ApiClient(this._store, this._config);

  /// API qua Gateway / Base URL
  Dio gateway() => _buildDio(_config.apiBaseUrl);

  /// Service riêng cho Page
  Dio pageService() => _buildDio(_config.pageServiceUrl);

  /// Service riêng cho Media
  Dio mediaService() => _buildDio(_config.mediaServiceUrl);

  Dio _buildDio(String baseUrl) {
    if (baseUrl.isEmpty) {
      throw StateError('Missing base URL. Check your --dart-define for API_BASE_URL / PAGE_SERVICE_URL / MEDIA_SERVICE_URL');
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'X-Client': 'flutter-app-v2'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _store.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final newToken = await _store.tryRefreshToken();
          if (newToken != null) {
            final request = e.requestOptions;
            request.headers['Authorization'] = 'Bearer $newToken';
            try {
              final cloneReq = await dio.fetch(request);
              return handler.resolve(cloneReq);
            } catch (err) {
              return handler.next(e);
            }
          }
        }
        handler.next(e);
      },
    ));

    // Logging chỉ bật khi env = development
    if (_config.isDevelopment) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ));
    }

    return dio;
  }
}

// Helper
Never mapDioError(DioException e) {
  final statusCode = e.response?.statusCode;
  final message = e.response?.data?.toString() ?? e.message;

  if (statusCode != null) {
    throw ApiFailure('HTTP $statusCode: $message', statusCode: statusCode);
  }
  throw NetworkFailure('No internet or server unreachable');
}
