import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/secure_store.dart';
import '../model/user.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStore _store;
  AuthRepository(this._dio, this._store);

  /// LOCAL LOGIN -> POST /api/rookie/users/auth/login
  Future<User> login({required String email, required String password}) async {
    try {
      final res = await _dio.post(
        '/api/rookie/users/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = (res.data as Map).cast<String, dynamic>();

      // Backend trả về { user: {...}, jwt: '...' }
      final userJson = (data['user'] ?? data).cast<String, dynamic>();
      final token = (data['jwt'] ??
          data['token'] ??
          data['accessToken'] ??
          '').toString();

      // Lưu token
      await _store.writeTokens(access: token, refresh: data['refreshToken']);

      return User.fromJson(userJson);
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ??
          e.response!.data['error']?.toString())
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Đăng nhập thất bại');
    }
  }

  /// LOGOUT -> POST /api/rookie/users/auth/logout
  Future<int?> logout() async {
    String? access = await _store.readAccessToken();
    int? ttlSeconds;

    try {
      if (access != null && access.isNotEmpty) {
        debugPrint('[AuthRepository] Logout with Bearer token...');

        final res = await _dio.post(
          '/api/rookie/users/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $access'}),
        );

        final data = (res.data is Map) ? (res.data as Map).cast<String, dynamic>() : <String, dynamic>{};
        ttlSeconds = (data['token_invalid_in_seconds'] as num?)?.toInt();

        debugPrint('[AuthRepository] Logout OK. token_invalid_in_seconds=$ttlSeconds');
        debugPrint('[AuthRepository] login ok userId');
        debugPrint('[AuthRepository] logout called');
      } else {
        debugPrint('[AuthRepository] Logout without token (no access token found).');
      }
    } on DioException catch (e) {
      debugPrint('[AuthRepository] Logout ERROR: '
          'status=${e.response?.statusCode} '
          'url=${e.requestOptions.uri} '
          'body=${e.response?.data}');
    } finally {
      await _store.clear();
    }

    return ttlSeconds;
  }

  /// REGISTER -> POST /api/rookie/users/auth/register
  Future<User> register({
    required String fullName,
    required String email,
    String? phoneNumber,
    required String password,
    String? roleId,
  }) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber?.trim(),
        'password': password,
      };

      if (roleId != null && roleId.trim().isNotEmpty) {
        body['roleId'] = roleId.trim();
      }

      final res = await _dio.post('/api/rookie/users/auth/register', data: body);
      final data = (res.data as Map).cast<String, dynamic>();

      // Backend trả về { user: {...}, jwt: '...' }
      final userJson = (data['user'] ?? data).cast<String, dynamic>();
      final token = (data['jwt'] ?? data['token'] ?? data['accessToken'] ?? '').toString();

      if (token.isNotEmpty) {
        // Không muốn auto-login
        await _store.writeTokens(access: token, refresh: data['refreshToken']);
      }

      return User.fromJson(userJson);
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? e.response!.data['error']?.toString())
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Đăng ký thất bại');
    }
  }

  /// FORGOT PASSWORD -> POST /api/rookie/users/auth/password/forgot
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        '/api/rookie/users/auth/password/forgot',
        data: {'email': email},
      );
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ??
          e.response!.data['error']?.toString())
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Không thể gửi yêu cầu đặt lại mật khẩu');
    }
  }

  /// GOOGLE LOGIN -> POST /api/rookie/users/auth/google
  Future<User> loginWithGoogle(String idToken) async {
    try {
      final res = await _dio.post(
        '/api/rookie/users/auth/google',
        data: {'idToken': idToken},
      );

      final data = (res.data as Map).cast<String, dynamic>();
      final userJson = (data['user'] ?? data).cast<String, dynamic>();
      final token = (data['jwt'] ?? data['token'] ?? data['accessToken'] ?? '').toString();

      await _store.writeTokens(access: token, refresh: data['refreshToken']);
      return User.fromJson(userJson);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ??
          e.response!.data['error']?.toString())
          : null;
      throw Exception(msg ?? e.message ?? 'Đăng nhập Google thất bại');
    }
  }

}
