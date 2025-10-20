import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/user.dart';

class UserRepository {
  final Dio _dio;
  UserRepository(this._dio);

  /// GET /api/rookie/users/{id}
  Future<User> getProfile(String userId) async {
    try {
      final res = await _dio.get('/api/rookie/users/$userId');
      return User.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ??
          e.response!.data['error']?.toString())
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Không lấy được thông tin người dùng');
    }
  }
}
