import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/role.dart';

class RoleRepository {
  final Dio _dio;
  RoleRepository(this._dio);

  Future<Role> getById(String roleId) async {
    try {
      final res = await _dio.get('/api/rookie/users/roles/$roleId');
      return Role.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      mapDioError(e);
    }
  }

  /// Lấy roleId ACTIVE theo roleName (Author/Customer)
  /// Gọi: /api/rookie/users/roles/search
  Future<String?> getActiveRoleIdByName(String roleName) async {
    try {
      final res = await _dio.get(
        '/api/rookie/users/roles/search',
        queryParameters: <String, dynamic>{
          'roleName': roleName,
          'isActived': 'ACTIVE',
          'page': 0,
          'size': 1,
        },
      );

      final data = (res.data as Map).cast<String, dynamic>();
      final content = (data['content'] as List?) ?? const [];
      if (content.isEmpty) return null;

      final first = (content.first as Map).cast<String, dynamic>();
      return first['roleId']?.toString();
    } on DioException catch (e) {
      mapDioError(e);
    }
  }

  /// Lấy roleId cho Author
  Future<String?> getAuthorRoleId() => getActiveRoleIdByName('Author');

  /// Lấy roleId cho Customer
  Future<String?> getCustomerRoleId() => getActiveRoleIdByName('Customer');

}
