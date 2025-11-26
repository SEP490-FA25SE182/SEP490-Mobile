// repository/address_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../core/api_client.dart';
import '../model/user_address.dart';

class AddressRepository {
  final Dio _dio;
  AddressRepository(this._dio);

  /// GET /api/rookie/users/addresses/user/{userId}
  Future<List<UserAddress>> listByUser(String userId) async {
    try {
      final res = await _dio.get('/api/rookie/users/addresses/user/$userId');

      final raw = res.data;
      final items = (raw is List) ? raw : <dynamic>[];

      return items
          .map((e) => UserAddress.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      debugPrint('[AddressRepo] listByUser ERROR '
          'status=${e.response?.statusCode} url=${e.requestOptions.uri} '
          'data=${e.response?.data}');
      // Trả list rỗng để UI vẫn chạy (hiện "Bạn chưa có địa chỉ...")
      return <UserAddress>[];
    }
  }

  ///POST /api/rookie/users/addresses
  Future<UserAddress> create({
    required String userId,
    required String fullName,
    required String addressInfor,
    String? phoneNumber,
    String? type,
    bool isDefault = false,
    String? provinceId,
    String? districtId,
    String? wardCode,
  }) async {
    try {
      final body = {
        'userId': userId,
        'fullName': fullName,
        'addressInfor': addressInfor,
        'phoneNumber': phoneNumber,
        'type': type,
        'isDefault': isDefault,
        'provinceId': provinceId,
        'districtId': districtId,
        'wardCode': wardCode,
      }..removeWhere((_, v) => v == null);

      final res = await _dio.post(
        '/api/rookie/users/addresses',
        data: [body],
        options: Options(contentType: Headers.jsonContentType),
      );

      final list = (res.data as List)
          .map((e) => UserAddress.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      return list.first;
    } on DioException catch (e) {
      debugPrint('[AddressRepo] create ERROR: ${e.response?.data}');
      mapDioError(e);
    }
  }

  ///PUT /api/rookie/users/addresses/{id}
  Future<UserAddress> update(
      String addressId, {
        required String fullName,
        required String addressInfor,
        String? phoneNumber,
        String? type,
        String? provinceId,
        String? districtId,
        String? wardCode,
      }) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullName,
        'addressInfor': addressInfor,
        'phoneNumber': phoneNumber,
        'type': type,
        'provinceId': provinceId,
        'districtId': districtId,
        'wardCode': wardCode,
      }..removeWhere((_, v) => v == null);

      final res = await _dio.put(
        '/api/rookie/users/addresses/$addressId',
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );

      return UserAddress.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      debugPrint('[AddressRepo] update ERROR: ${e.response?.data}');
      mapDioError(e);
    }
  }

  ///DELETE /api/rookie/users/addresses/$addressId
  Future<void> remove(String addressId) async {
    try {
      await _dio.delete('/api/rookie/users/addresses/$addressId');
    } on DioException catch (e) {
      mapDioError(e);
    }
  }

  Future<void> setDefault(String addressId) async {
    try {
      await _dio.put('/api/rookie/users/addresses/$addressId/default');
    } on DioException catch (e) {
      mapDioError(e);
    }
  }

  /// GET /api/rookie/users/addresses/{id}
  Future<UserAddress?> getOne(String id) async {
    try {
      final res = await _dio.get('/api/rookie/users/addresses/$id');
      return UserAddress.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (_) {
      return null;
    }
  }
}
