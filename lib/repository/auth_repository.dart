import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/secure_store.dart';
import '../model/user.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStore _store;
  AuthRepository(this._dio, this._store);

  /// Đăng nhập demo: POST /auth/login {email, password}
  Future<User> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      // server nên trả { accessToken, refreshToken, user:{...} }
      final data = res.data as Map<String, dynamic>;
      await _store.writeTokens(
        access: data['accessToken'] ?? '',
        refresh: data['refreshToken'],
      );
      return User.fromJson(data['user'] ?? {});
    } on DioException catch (e) {
      mapDioError(e);
    }
  }

  Future<User> me() async {
    try {
      final res = await _dio.get('/auth/me');
      return User.fromJson(res.data);
    } on DioException catch (e) {
      mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _store.clear();
  }
}
