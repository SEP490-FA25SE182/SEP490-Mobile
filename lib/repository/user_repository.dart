import 'package:dio/dio.dart';
import 'package:sep490_mobile/repository/role_repository.dart';
import '../core/api_client.dart';
import '../model/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider.dart';

class UserRepository {
  final Dio _dio;
  final Ref? ref;

  UserRepository(this._dio, [this.ref]);

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


  Future<User?> getUserById(String id) async {
    try {
      final res = await _dio.get('/api/rookie/users/$id');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      mapDioError(e);
      return null;
    }
  }


  Future<List<User>> getAllAuthors() async {
    try {
      String? authorRoleId;

      if (ref != null) {
        authorRoleId = await ref!.read(authorRoleIdProvider.future);
      }

      if (authorRoleId == null) {
        final roleRepo = RoleRepository(_dio);
        authorRoleId = await roleRepo.getAuthorRoleId();
      }

      if (authorRoleId == null) {
        print('Không tìm thấy roleId của Author');
        return [];
      }

      final res = await _dio.get(
        '/api/rookie/users/search',
        queryParameters: {
          'roleId': authorRoleId,
          'isActived': 'ACTIVE',
          'size': 200,
        },
      );

      final content = (res.data['content'] as List?) ?? [];
      return content
          .map((e) => User.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      mapDioError(e);
      return [];
    }
  }
}
