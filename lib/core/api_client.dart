import 'package:dio/dio.dart';
import 'config.dart';
import 'secure_store.dart';
import 'failures.dart';

Dio buildDio(AppConfig cfg, SecureStore store) {
  if (cfg.apiBaseUrl.isEmpty) {
    throw StateError('Missing API_BASE_URL. Pass via --dart-define.');
  }

  final dio = Dio(BaseOptions(
    baseUrl: cfg.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'X-Client': 'flutter-app'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (o, h) async {
      final token = await store.readAccessToken();
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    },
    onError: (e, h) async {
      if (e.response?.statusCode == 401) {
        final newToken = await store.tryRefreshToken();
        if (newToken != null) {
          final req = e.requestOptions;
          req.headers['Authorization'] = 'Bearer $newToken';
          final res = await dio.fetch(req);
          return h.resolve(res);
        }
      }
      h.next(e);
    },
  ));

  return dio;
}

Never mapDioError(DioException e) {
  final sc = e.response?.statusCode;
  if (sc != null) throw ApiFailure('HTTP $sc: ${e.message}', statusCode: sc);
  throw NetworkFailure('Network error: ${e.message}');
}
