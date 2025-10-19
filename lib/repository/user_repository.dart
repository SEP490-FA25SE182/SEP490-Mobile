import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/user.dart';

class UserRepository {
  final Dio _dio;
  UserRepository(this._dio);

  Future<User> getProfile(String userId) async {
    try {
      final res = await _dio.get('/users/$userId');
      return User.fromJson(res.data);
    } on DioException catch (e) {
      mapDioError(e);
    }
  }
}
