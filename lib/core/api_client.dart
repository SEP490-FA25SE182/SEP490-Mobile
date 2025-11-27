// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'env.dart';
import 'secure_store.dart';
import 'failures.dart';

class ApiClient {
  final SecureStore _store;

  ApiClient(this._store);

  /// API throw Gateway (8080) – production & staging
  Dio gateway() => _buildDio(Env.apiBaseUrl);

  /// Use for dev local – directly call to service
  Dio pageService() => _buildDio(Env.pageServiceUrl);
  Dio mediaService() => _buildDio(Env.mediaServiceUrl);

  Dio _buildDio(String baseUrl) {
    if (baseUrl.isEmpty) {
      throw StateError('Missing base URL. Check your .env or --dart-define');
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

    // Optional: Logging (chỉ bật khi dev)
    if (Env.isDevelopment) {
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