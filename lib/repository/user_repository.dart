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

  /// PUT /api/rookie/users/{id}
  Future<User> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        if (fullName != null)   'fullName'  : fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (gender != null)     'gender'    : gender,
        if (birthDate != null)  'birthDate' : birthDate.toIso8601String().split('T').first,
        if (avatarUrl != null)  'avatarUrl' : avatarUrl,
      };

      final res = await _dio.put('/api/rookie/users/$userId', data: body);
      return User.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      mapDioError(e);
    }
  }
}
